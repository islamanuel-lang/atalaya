//
//  RootView.swift
//  Atalaya
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            DS.ink.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .tint(DS.signal)
        .task { await model.bootstrap() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, let api = model.api {
                Task { await Pending.shared.flush(api: api) }
            }
        }
        .overlay(alignment: .bottom) {
            if let banner = model.banner {
                Text(banner)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(DS.warn)
                    .padding(16)
                    .onTapGesture { model.banner = nil }
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.banner)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                model.screen = .welcome
            } label: {
                HStack(spacing: 8) {
                    Mark(size: 22)
                    Text("atalaya")
                        .font(.system(size: 18, weight: .medium))
                        .tracking(-0.4)
                        .foregroundStyle(DS.text)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Inicio")

            Spacer()

            if model.patched {
                Text("parcheado")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.warn)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(Capsule().stroke(DS.warn.opacity(0.4)))
            }

            Button { model.screen = .log } label: {
                Image(systemName: "terminal")
                    .foregroundStyle(DS.mute)
            }
            Button { model.screen = .settings } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(DS.mute)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch model.screen {
        case .welcome: WelcomeView()
        case .detection: DetectionView()
        case .address: AddressView()
        case .seedIntro: SeedIntroView()
        case .seed: SeedEntryView()
        case .audit: AuditView()
        case .report: ReportView()
        case .settings: SettingsView()
        case .log: LogView()
        }
    }
}

#Preview {
    RootView().environmentObject(AppModel())
}
