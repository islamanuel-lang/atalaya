//
//  LogView.swift
//  Atalaya
//

import SwiftUI
import UIKit

struct LogView: View {
    @EnvironmentObject private var model: AppModel
    @State private var tick = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ScreenHeader(eyebrow: "Diagnóstico", title: "Log")
                Spacer(minLength: 8)
                ShareLink(item: Log.shared.text) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(DS.mute)
                }
                Button {
                    UIPasteboard.general.string = Log.shared.text
                    model.banner = "Log copiado."
                } label: {
                    Image(systemName: "doc.on.doc").foregroundStyle(DS.mute)
                }
            }

            ScrollView {
                Text(Log.shared.text.isEmpty ? "Sin entradas." : Log.shared.text)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DS.mute)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .id(tick)
            }

            HStack {
                Button("Vaciar") { Log.shared.clear(); tick += 1 }
                    .buttonStyle(GhostButtonStyle())
                Button("Volver") { model.screen = .settings }
                    .buttonStyle(GhostButtonStyle())
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .onReceive(timer) { _ in tick += 1 }
    }
}
