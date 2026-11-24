//
//  BIP39.swift
//  SemenCheck
//
//  Validación local de la frase: diccionario y checksum. La derivación de
//  direcciones se hace en el servidor para no cargar secp256k1 en la app.
//

import CryptoKit
import Foundation

enum BIP39 {
    enum Result {
        case empty
        case invalidCount(Int)
        case unknownWord(position: Int, word: String)
        case checksum
        case valid([String])
    }

    static let words: [String] = {
        guard let url = Bundle.main.url(forResource: "bip39-english", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            log("No se pudo cargar la wordlist BIP-39")
            return []
        }
        return text.split(separator: "\n").map(String.init)
    }()

    private static let index: [String: Int] = {
        var map: [String: Int] = [:]
        for (i, word) in words.enumerated() { map[word] = i }
        return map
    }()

    static func normalize(_ input: String) -> [String] {
        input
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
            .lowercased()
            .split { !$0.isLetter }
            .map(String.init)
    }

    static func validate(_ input: String) -> Result {
        let tokens = normalize(input)
        if tokens.isEmpty { return .empty }
        guard [12, 15, 18, 21, 24].contains(tokens.count) else {
            return .invalidCount(tokens.count)
        }

        var indices: [Int] = []
        for (position, token) in tokens.enumerated() {
            guard let value = index[token] else {
                return .unknownWord(position: position + 1, word: token)
            }
            indices.append(value)
        }

        let totalBits = tokens.count * 11
        let checksumBits = totalBits / 33
        let entropyBits = totalBits - checksumBits

        var bits: [Bool] = []
        bits.reserveCapacity(totalBits)
        for value in indices {
            for shift in stride(from: 10, through: 0, by: -1) {
                bits.append((value >> shift) & 1 == 1)
            }
        }

        var entropy = [UInt8](repeating: 0, count: entropyBits / 8)
        for i in 0..<entropyBits where bits[i] {
            entropy[i / 8] |= 0x80 >> (i % 8)
        }
        let hash = Array(SHA256.hash(data: Data(entropy)))
        for i in 0..<checksumBits {
            let expected = (hash[i / 8] >> (7 - (i % 8))) & 1 == 1
            if bits[entropyBits + i] != expected { return .checksum }
        }
        return .valid(tokens)
    }

    static func message(for result: Result) -> String? {
        switch result {
        case .empty:
            return nil
        case .invalidCount(let count):
            return "Faltan palabras: \(count) de 12."
        case .unknownWord(let position, let word):
            return "La palabra \(position) («\(word)») no está en el diccionario."
        case .checksum:
            return "Revisa el orden: el checksum no cuadra."
        case .valid:
            return "Frase válida."
        }
    }
}
