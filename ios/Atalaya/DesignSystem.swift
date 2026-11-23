//
//  DesignSystem.swift
//  Atalaya
//

import SwiftUI

enum DS {
    static let ink = Color(hex: 0x0A0E12)
    static let surface = Color(hex: 0x121821)
    static let line = Color(hex: 0x22303F)
    static let text = Color(hex: 0xE8EDF2)
    static let mute = Color(hex: 0x93A1B0)
    static let signal = Color(hex: 0x2ED47A)
    static let warn = Color(hex: 0xF5A524)
    static let risk = Color(hex: 0xF04438)

    static let radius: CGFloat = 16
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1)
    }
}

struct TowerMark: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        // base
        path.move(to: CGPoint(x: 0.22 * w, y: 0.86 * h))
        path.addLine(to: CGPoint(x: 0.78 * w, y: 0.86 * h))
        // cuerpo
        path.move(to: CGPoint(x: 0.32 * w, y: 0.86 * h))
        path.addLine(to: CGPoint(x: 0.40 * w, y: 0.36 * h))
        path.addLine(to: CGPoint(x: 0.60 * w, y: 0.36 * h))
        path.addLine(to: CGPoint(x: 0.68 * w, y: 0.86 * h))
        // haz
        path.move(to: CGPoint(x: 0.40 * w, y: 0.36 * h))
        path.addLine(to: CGPoint(x: 0.24 * w, y: 0.20 * h))
        path.move(to: CGPoint(x: 0.60 * w, y: 0.36 * h))
        path.addLine(to: CGPoint(x: 0.76 * w, y: 0.20 * h))
        return path
    }
}

struct Mark: View {
    var size: CGFloat = 44
    var body: some View {
        ZStack(alignment: .top) {
            TowerMark()
                .stroke(DS.signal, style: StrokeStyle(lineWidth: size * 0.075,
                                                      lineCap: .round, lineJoin: .round))
            Circle()
                .fill(DS.signal)
                .frame(width: size * 0.09)
                .offset(y: size * 0.12)
        }
        .frame(width: size, height: size)
    }
}

struct ScreenHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(DS.mute)
            }
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .default))
                .foregroundStyle(DS.text)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(DS.mute)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                    .stroke(DS.line, lineWidth: 1))
    }
}

struct Micro: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(DS.mute)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct Mono: View {
    let text: String
    var size: CGFloat = 13
    var body: some View {
        Text(text)
            .font(.system(size: size, design: .monospaced))
            .foregroundStyle(DS.text)
            .textSelection(.enabled)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(enabled ? DS.ink : DS.mute)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(enabled ? DS.signal.opacity(configuration.isPressed ? 0.8 : 1) : DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(enabled ? .clear : DS.line, lineWidth: 1))
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(DS.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? DS.surface.opacity(0.7) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DS.line, lineWidth: 1))
    }
}

struct RiskPill: View {
    let risk: String

    private var color: Color {
        switch risk {
        case "high": return DS.risk
        case "medium": return DS.warn
        default: return DS.signal
        }
    }

    private var label: String {
        switch risk {
        case "high": return "Riesgo alto"
        case "medium": return "Riesgo medio"
        default: return "Riesgo bajo"
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(DS.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }
}

struct StateDot: View {
    let state: ProgressStep.State

    var body: some View {
        Group {
            switch state {
            case .pending:
                Circle().stroke(DS.line, lineWidth: 2)
            case .running:
                ProgressView().tint(DS.signal).scaleEffect(0.7)
            case .done:
                Circle().fill(DS.signal)
            case .failed:
                Circle().fill(DS.warn)
            }
        }
        .frame(width: 22, height: 22)
    }
}
