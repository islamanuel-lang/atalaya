//
//  SeedOCR.swift
//  SemenCheck
//
//  OCR de una captura. Devuelve la primera ventana válida de 12/24 palabras.
//

import UIKit
import Vision

enum SeedOCR {
    static func phrase(from image: UIImage) async -> [String]? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false

                let handler = VNImageRequestHandler(cgImage: cgImage)
                do {
                    try handler.perform([request])
                } catch {
                    log("OCR falló: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                let text = (request.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")

                let tokens = BIP39.normalize(text)
                for size in [24, 12] where tokens.count >= size {
                    for start in 0...(tokens.count - size) {
                        let window = Array(tokens[start..<(start + size)])
                        if case .valid = BIP39.validate(window.joined(separator: " ")) {
                            continuation.resume(returning: window)
                            return
                        }
                    }
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
