//
//  SeedIntroView.swift
//  SemenCheck
//

import SwiftUI

struct SeedIntroView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(
                    eyebrow: "La parte importante",
                    title: "Ahora, la frase",
                    subtitle: "Una dirección dice cuánto tienes. La frase dice si está en filtraciones.")

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        reason("key.horizontal", "Sin la frase no se puede comprobar una filtración")
                        reason("signature", "La app no firma: solo lee")
                        reason("trash", "Puedes borrarla al terminar")
                    }
                }

                Button("Comprobar mi frase") { model.screen = .seed }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Volver a la dirección") { model.screen = .address }
                    .buttonStyle(GhostButtonStyle())

                Micro(text: "12 o 24 palabras, separadas por espacios. Validamos el diccionario y el checksum.")
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    private func reason(_ icon: String, _ text: String) -> some View {
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
