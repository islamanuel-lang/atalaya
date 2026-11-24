//
//  SemenCheckApp.swift
//  SemenCheck
//

import SwiftUI

@main
struct SemenCheckApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}
