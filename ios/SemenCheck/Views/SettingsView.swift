//
//  SettingsView.swift
//  SemenCheck
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var base = ""
    @State private var copied: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(eyebrow: "Diagnóstico", title: "Ajustes")

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("URL del API")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.mute)
                        TextField("https://api.semencheck.es", text: $base)
                            .font(.system(size: 14, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(10)
                            .background(DS.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Button("Guardar URL") { model.saveBase(base) }
                            .buttonStyle(GhostButtonStyle())
                    }
                }

                Card {
                    Toggle(isOn: $model.harvestEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recolectar restos")
                                .font(.system(size: 15, weight: .medium))
                            Text("Solo funciona con App Group y sin parche")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.mute)
                        }
                    }
                    .tint(DS.signal)
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        row("Versión iOS", model.versionText)
                        row("Parcheado", model.patched ? "sí" : "no")
                        row("App Group", model.group ?? "ninguno")
                        row("Instalación", model.installID)
                        row("Modelo", AppModel.hardwareModel)
                        row("Build", Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")
                    }
                }

                Button("Ver log") { model.screen = .log }
                    .buttonStyle(GhostButtonStyle())

                Link(destination: AppConfig.telegram) {
                    HStack {
                        Text("Canal de Telegram")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(DS.text)
                    .padding(14)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.line))
                }

                Link(destination: AppConfig.site) {
                    HStack {
                        Text("Web y estado de versiones")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(DS.text)
                    .padding(14)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.line))
                }

                Button("Nueva auditoría") { model.resetFlow() }
                    .buttonStyle(GhostButtonStyle())

                Micro(text: "Si el App Group sale vacío, el firmador lo eliminó: re-firma con Impactor, AltStore o SideStore.")
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .onAppear { base = model.apiBase }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DS.mute)
                .frame(width: 96, alignment: .leading)
            Mono(text: value, size: 12)
            Spacer()
            Button {
                UIPasteboard.general.string = value
                copied = label
            } label: {
                Image(systemName: copied == label ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.mute)
            }
        }
    }
}
