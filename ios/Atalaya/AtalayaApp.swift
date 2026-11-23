//
//  AtalayaApp.swift
//  Atalaya
//

import SwiftUI

@main
struct AtalayaApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}
