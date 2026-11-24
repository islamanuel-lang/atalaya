//
//  AddressView.swift
//  SemenCheck
//

import SwiftUI

struct AddressView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(
                    eyebrow: "Sin riesgo",
                    title: "Empieza por lo fácil",
                    subtitle: "Pega una dirección pública. Verás saldo sin dar acceso a nada.")

                TextField("0x… o dirección BTC/SOL", text: $model.address)
                    .font(.system(size: 15, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .padding(14)
                    .background(DS.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.line))

                Button {
                    Task { await model.submitAddress() }
                } label: {
                    if model.busy {
                        ProgressView().tint(DS.ink)
                    } else {
                        Text("Ver informe")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(model.busy || model.address.count < 20)

                if let report = model.addressReport {
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            RiskPill(risk: report.risk)
                            if report.addresses.isEmpty {
                                Text("Sin actividad visible.")
                                    .foregroundStyle(DS.mute)
                            }
                            ForEach(report.addresses) { item in
                                HStack {
                                    Text(item.chain)
                                        .foregroundStyle(DS.mute)
                                    Spacer()
                                    Text(item.displayAmount)
                                        .foregroundStyle(DS.text)
                                }
                                .font(.system(size: 14, design: .monospaced))
                            }
                        }
                    }
                }

                Button("Comprobar mi frase") { model.screen = .seedIntro }
                    .buttonStyle(GhostButtonStyle())

                Micro(text: "Una dirección no da acceso a tu dinero. La frase hace falta solo para comprobar filtraciones.")
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}
