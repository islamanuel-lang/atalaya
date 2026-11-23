//
//  AuditView.swift
//  Atalaya
//

import SwiftUI

struct AuditView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(
                eyebrow: "No cierres la app",
                title: "Revisando tu iPhone",
                subtitle: "Menos de un minuto. La búsqueda de inodos es la parte lenta.")

            Card {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(model.steps) { step in
                        HStack(spacing: 12) {
                            StateDot(state: step.state)
                            Text(step.title)
                                .font(.system(size: 15))
                                .foregroundStyle(step.state == .pending ? DS.mute : DS.text)
                        }
                    }
                }
            }

            if !model.note.isEmpty {
                Mono(text: model.note, size: 12)
                    .foregroundStyle(DS.mute)
            }

            Spacer()

            Button("Cancelar") { model.cancelAudit() }
                .buttonStyle(GhostButtonStyle())
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .navigationBarBackButtonHidden()
    }
}
