//
//  ReportView.swift
//  SemenCheck
//

import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showMigrate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let report = model.report {
                    ScreenHeader(
                        eyebrow: "Informe",
                        title: riskTitle(report.risk),
                        subtitle: reportSubtitle(report))
                    HStack { RiskPill(risk: report.risk); Spacer() }

                    if report.totalUsd > 0 {
                        Card {
                            HStack {
                                Text("Total visible")
                                    .foregroundStyle(DS.mute)
                                Spacer()
                                Text(String(format: "%.2f USD", report.totalUsd))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundStyle(DS.signal)
                            }
                        }
                    }

                    if !report.addresses.isEmpty {
                        section("Direcciones")
                        ForEach(report.addresses) { item in
                            Card {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.chain.uppercased())
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(DS.mute)
                                        Spacer()
                                        Text(item.displayAmount)
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundStyle(DS.text)
                                    }
                                    Mono(text: item.address, size: 12)
                                }
                            }
                        }
                    }

                    if !report.findings.isEmpty {
                        section("Hallazgos")
                        ForEach(report.findings) { finding in
                            Card {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(finding.severity == "high" ? DS.risk
                                                  : finding.severity == "medium" ? DS.warn : DS.line)
                                            .frame(width: 7, height: 7)
                                        Text(finding.source)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(DS.mute)
                                    }
                                    Text(finding.detail)
                                        .font(.system(size: 14))
                                        .foregroundStyle(DS.text)
                                    if !finding.path.isEmpty {
                                        Mono(text: finding.path, size: 11)
                                            .foregroundStyle(DS.mute)
                                    }
                                }
                            }
                        }
                    } else {
                        Card {
                            Text("Sin hallazgos. Aun así, deja de guardar la semilla en digital.")
                                .font(.system(size: 14))
                                .foregroundStyle(DS.mute)
                        }
                    }

                    ShareLink(item: model.shareText) {
                        Text("Compartir informe")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DS.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(DS.signal)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button("Cómo migrar") { showMigrate = true }
                        .buttonStyle(GhostButtonStyle())

                    Button("Nueva auditoría") { model.resetFlow() }
                        .buttonStyle(GhostButtonStyle())

                    Micro(text: "Fuente de los hallazgos: archivos de apps y capturas del carrete. Revisa siempre la coincidencia de dirección.")
                        .padding(.bottom, 30)
                } else {
                    Text("Sin informe todavía.")
                        .foregroundStyle(DS.mute)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showMigrate,
               onDismiss: { model.clearSeed() }) {
            MigrateView()
        }
    }

    private func riskTitle(_ risk: String) -> String {
        switch risk {
        case "high": return "Tu frase está expuesta"
        case "medium": return "Hay restos en el móvil"
        default: return "Sin exposición conocida"
        }
    }

    private func reportSubtitle(_ report: AuditReport) -> String {
        let leaks = report.findings.filter { $0.source == "filtracion" }.count
        let files = report.findings.filter { $0.source == "archivo" }.count
        return "\(leaks) filtraciones · \(files) restos · \(report.addresses.count) direcciones"
    }

    private func section(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(DS.mute)
    }
}

struct MigrateView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    step(1, "Crea una wallet nueva en otro dispositivo y apunta la frase en papel.")
                    step(2, "Pasa primero los tokens y después el gas. En Ethereum usa un canal privado.")
                    step(3, "Revoca aprobaciones de la wallet vieja.")
                    step(4, "Borra capturas, notas y archivos con la frase antigua.")
                    step(5, "Vacía la papelera de Fotos y de Archivos.")
                    Text("Una frase expuesta se considera quemada: no vuelvas a usarla.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.warn)
                        .padding(.top, 8)
                }
                .padding(24)
            }
            .background(DS.ink)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hecho") { dismiss() }
                }
            }
            .navigationTitle("Migrar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private func step(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.ink)
                .frame(width: 22, height: 22)
                .background(DS.signal)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(DS.text)
        }
    }
}
