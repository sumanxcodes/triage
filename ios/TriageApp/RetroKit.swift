import SwiftUI
import UIKit

// MARK: - ComponentsKit Retro Theme System (Inspired by componentskit.dev)

public struct RetroTheme {
    /// Canvas Background: Vintage CRT Dark in Dark Mode, Retro Computer Beige/Paper in Light Mode
    public static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 12/255.0, green: 13/255.0, blue: 14/255.0, alpha: 1.0) : // #0C0D0E CRT Dark
            UIColor(red: 244/255.0, green: 242/255.0, blue: 236/255.0, alpha: 1.0) // #F4F2EC Vintage Beige
    })

    /// Card Surface: Deep Terminal Slate in Dark, Crisp Card White in Light
    public static let surface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 22/255.0, green: 24/255.0, blue: 27/255.0, alpha: 1.0) : // #16181B
            UIColor.white
    })

    /// Elevated Surface for sub-components, inputs, and chips
    public static let elevatedSurface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 32/255.0, green: 35/255.0, blue: 39/255.0, alpha: 1.0) :
            UIColor(red: 235/255.0, green: 232/255.0, blue: 224/255.0, alpha: 1.0)
    })

    /// Retro Solid Line Border: 2pt high-contrast outline
    public static let border = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(white: 0.88, alpha: 1.0) :
            UIColor(white: 0.08, alpha: 1.0)
    })

    /// Retro Hard Offset Drop Shadow (unblurred mechanical drop shadow)
    public static let shadow = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor.black.withAlphaComponent(0.85) :
            UIColor(white: 0.08, alpha: 1.0)
    })

    /// Phosphor Cyber Volt Accent (#D4FF3A)
    public static let volt = Color(red: 212/255.0, green: 255/255.0, blue: 58/255.0)

    /// Adaptive Terminal Text Accent (Phosphor Volt in Dark, Deep Terminal Olive in Light)
    public static let textAccent = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 212/255.0, green: 255/255.0, blue: 58/255.0, alpha: 1.0) :
            UIColor(red: 55/255.0, green: 80/255.0, blue: 0/255.0, alpha: 1.0)
    })

    /// Terminal Amber Warning Accent (#FFA000)
    public static let amber = Color(red: 255/255.0, green: 160/255.0, blue: 0/255.0)

    /// Adaptive Terminal Amber Text
    public static let textAmber = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor(red: 255/255.0, green: 160/255.0, blue: 0/255.0, alpha: 1.0) :
            UIColor(red: 175/255.0, green: 80/255.0, blue: 0/255.0, alpha: 1.0)
    })
}

// MARK: - Retro UI Components

/// Retro Card: Heavy solid 2pt border with a mechanical offset unblurred drop shadow
public struct RetroCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let content: Content

    public init(cornerRadius: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(RetroTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(RetroTheme.border, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(RetroTheme.shadow)
                    .offset(x: 3, y: 3)
            )
    }
}

/// Retro Button Style: Physically presses into its shadow on touch down
public struct RetroButtonStyle: ButtonStyle {
    public var backgroundColor: Color
    public var foregroundColor: Color
    public var cornerRadius: CGFloat

    public init(
        backgroundColor: Color = RetroTheme.volt,
        foregroundColor: Color = .black,
        cornerRadius: CGFloat = 8
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(RetroTheme.border, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(RetroTheme.shadow)
                    .offset(x: configuration.isPressed ? 0 : 3, y: configuration.isPressed ? 0 : 3)
            )
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Retro Bracketed Badge Tag: e.g. [ ONLINE ], [ ACTIVE ], [ SETUP ]
public struct RetroBadge: View {
    public let text: String
    public let color: Color
    public let isFilled: Bool

    public init(_ text: String, color: Color = RetroTheme.textAccent, isFilled: Bool = false) {
        self.text = text
        self.color = color
        self.isFilled = isFilled
    }

    public var body: some View {
        HStack(spacing: 3) {
            Text("[")
                .foregroundColor(color.opacity(0.6))
            Text(text.uppercased())
                .foregroundColor(color)
            Text("]")
                .foregroundColor(color.opacity(0.6))
        }
        .font(.system(size: 11, weight: .heavy, design: .monospaced))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isFilled ? color.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(isFilled ? color.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}

/// Retro Block Telemetry Meter (Segmented pixel-style capacity bar)
public struct RetroBlockMeter: View {
    public let filledBlocks: Int
    public let totalBlocks: Int
    public let color: Color

    public init(filled: Int = 12, total: Int = 16, color: Color = RetroTheme.textAccent) {
        self.filledBlocks = filled
        self.totalBlocks = total
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<totalBlocks, id: \.self) { index in
                Rectangle()
                    .fill(index < filledBlocks ? color : Color.primary.opacity(0.12))
                    .frame(height: 7)
            }
        }
        .padding(3)
        .background(RetroTheme.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(RetroTheme.border, lineWidth: 1)
        )
    }
}
