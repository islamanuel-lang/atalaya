//
//  DetectionView.swift
//  Atalaya
//

import SwiftUI

struct DetectionView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScreenHeader(
                eyebrow: "Detección local",
                title: "Esto es lo que hay en tu iPhone",
                subtitle: "Wallets y apps relevantes detectadas. Todavía no se ha abierto nada.")

            if model.installed.isEmpty {
                Card {
                    Text("No hemos detectado wallets del catálogo. Puedes continuar igualmente.")
                        .foregroundStyle(DS.mute)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.installed) { app in
                            Card {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(app.tier == 1 ? DS.signal : DS.line)
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(DS.text)
                                        Text(app.bundleID)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(DS.mute)
                                    }
                                    Spacer()
                                    Text(app.tier == 1 ? "wallet" : "app")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(DS.mute)
                                }
                            }
                        }
                    }
                }
            }

            Button("Continuar") { model.nextFromDetection() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Saltar detección") { model.screen = .address }
                .buttonStyle(GhostButtonStyle())

            Micro(text: "La detección es local. Nada se sube hasta que audites.")
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
