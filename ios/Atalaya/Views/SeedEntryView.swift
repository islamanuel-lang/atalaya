//
//  SeedEntryView.swift
//  Atalaya
//

import PhotosUI
import SwiftUI
import UIKit

struct SeedEntryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var photo: PhotosPickerItem?
    @State private var reading = false

    private var count: Int { BIP39.normalize(model.seed).count }

    private var messageColor: Color {
        if case .valid = model.validation { return DS.signal }
        if case .empty = model.validation { return DS.mute }
        return DS.warn
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(
                    eyebrow: "12 o 24 palabras",
                    title: "Tu frase semilla",
                    subtitle: "Pega o escribe. Se valida en el dispositivo antes de enviarse.")

                ZStack(alignment: .topLeading) {
                    if model.seed.isEmpty {
                        Text("abandon ability able …")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(DS.mute.opacity(0.6))
                            .padding(16)
                    }
                    TextEditor(text: Binding(
                        get: { model.seed },
                        set: { model.updateSeed($0) }))
                        .font(.system(size: 16, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150)
                        .padding(10)
                }
                .background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.line))

                HStack {
                    Text("\(count) palabras")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(count == 12 || count == 24 ? DS.signal : DS.mute)
                    Spacer()
                    if let message = model.validationMessage {
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundStyle(messageColor)
                            .multilineTextAlignment(.trailing)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        if let text = UIPasteboard.general.string { model.updateSeed(text) }
                    } label: {
                        Label("Pegar", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(GhostButtonStyle())

                    PhotosPicker(selection: $photo, matching: .images) {
                        HStack(spacing: 6) {
                            if reading { ProgressView().tint(DS.text) }
                            else { Image(systemName: "photo") }
                            Text("Desde una foto")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DS.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.line))
                    }
                }

                Button {
                    model.startAudit()
                } label: {
                    Text("Comprobar ahora")
                }
                .buttonStyle(PrimaryButtonStyle(enabled: model.canAudit))
                .disabled(!model.canAudit)

                Button("Borrar frase") { model.clearSeed() }
                    .buttonStyle(GhostButtonStyle())

                Micro(text: "La frase se envía a la API para derivar direcciones y comparar filtraciones. No se usa para firmar.")
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            reading = true
            Task {
                defer { reading = false }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    model.banner = "No se pudo leer la imagen."
                    return
                }
                if let words = await SeedOCR.phrase(from: image) {
                    model.fillSeed(words)
                } else {
                    model.banner = "No encontramos una frase válida en la foto."
                }
            }
        }
    }
}
