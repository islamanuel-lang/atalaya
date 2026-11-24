//
//  WelcomeView.swift
//  SemenCheck
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showHow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Mark(size: 72)
                    .padding(.top, 20)

                ScreenHeader(
                    eyebrow: "Auditoría de wallet",
                    title: "¿Está tu frase semilla expuesta?",
                    subtitle: "En 60 segundos. Sin registro y sin permisos. Solo lectura: la app no firma nada.")

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        bullet("magnifyingglass", "Detectamos tus wallets instaladas")
                        bullet("photo.on.rectangle", "Revisamos si la semilla vive en fotos o archivos")
                        bullet("checkmark.shield", "Comprobamos filtraciones conocidas")
                    }
                }

                Button("Auditar ahora") { model.begin() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Cómo funciona") { showHow = true }
                    .buttonStyle(GhostButtonStyle())

                Link(destination: AppConfig.telegram) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane")
                        Text("Canal de Telegram")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.line))
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(model.group == nil ? DS.warn : DS.signal)
                        .frame(width: 6, height: 6)
                    Text(model.group == nil ? "Sin App Group: firma la build" : "App Group listo")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.mute)
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showHow) {
            HowItWorksView()
        }
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(DS.signal)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(DS.text)
        }
    }
}

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("SemenCheck revisa lo que tú no ves")
                        .font(.system(size: 24, weight: .bold))
                    Text("Un fallo de iOS 26 y 27 permite que una app lea las carpetas de otras. SemenCheck lo aprovecha para buscar restos de tu semilla: capturas, archivos y respaldos.")
                        .foregroundStyle(DS.mute)
                    Text("Qué no hace")
                        .font(.system(size: 18, weight: .semibold))
                    Text("No es una wallet, no custodia fondos y no firma transacciones. La frase se usa para derivar direcciones y comparar filtraciones.")
                        .foregroundStyle(DS.mute)
                    Text("Qué versiones")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Funciona hasta iOS 27.3 beta 1. Desde 27.3 beta 2 Apple lo parcheó y solo queda la auditoría en línea.")
                        .foregroundStyle(DS.mute)
                }
                .padding(24)
            }
            .background(DS.ink)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .navigationTitle("Cómo funciona")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}
