import SwiftUI
import UIKit
import ComponentsKit

// MARK: - ComponentsKit Official Retro Theme Engine

public struct RetroTheme {
    /// Canvas Background: Vintage CRT Dark in Dark Mode, Retro Computer Beige/Paper in Light Mode
    public static var background: Color { UniversalColor.background.color }

    /// Card Surface: Deep Terminal Slate in Dark, Crisp Card White in Light
    public static var surface: Color { UniversalColor.secondaryBackground.color }

    /// Elevated Surface for sub-components, inputs, and chips
    public static var elevatedSurface: Color { UniversalColor.content1.color }

    /// Retro Solid Line Border: high-contrast outline
    public static var border: Color { UniversalColor.divider.color }

    /// Retro Hard Offset Drop Shadow (unblurred mechanical drop shadow)
    public static var shadow: Color { Theme.current.layout.shadow.medium.color.color }

    /// Phosphor Cyber Volt Accent (#D4FF3A / #19E58C)
    public static var volt: Color { UniversalColor.primary.color }

    /// Terminal Text Accent
    public static var textAccent: Color { UniversalColor.primary.color }

    /// Terminal Amber Warning Accent (#FFA000)
    public static var amber: Color { UniversalColor.warning.color }

    /// Terminal Amber Text
    public static var textAmber: Color { UniversalColor.warning.color }

    /// Phosphor Red: destructive/critical alert accent
    public static var red: Color { UniversalColor.danger.color }

    /// Configures ComponentsKit's global theme engine to match the Retro Theme
    public static func configureComponentsKit() {
        var palette = Theme.Palette()
        // Canvas Background: #F4F2EC in Light Mode, #0C0D0E in Dark Mode
        palette.background = .themed(
            light: .hex("#F4F2EC"),
            dark: .hex("#0C0D0E")
        )
        // Card Surface: Pure Crisp White in Light Mode, Terminal Dark #16181B in Dark Mode
        palette.secondaryBackground = .themed(
            light: .hex("#FFFFFF"),
            dark: .hex("#16181B")
        )
        // Sub-elements / elevated chips
        palette.content1 = .themed(
            light: .hex("#EBE7DC"),
            dark: .hex("#202327")
        )
        palette.content2 = .themed(
            light: .hex("#D9D5CA"),
            dark: .hex("#2A2E34")
        )
        // Primary Text: High-contrast Dark #141414 in Light Mode, Crisp #EDEDED in Dark Mode
        palette.foreground = .themed(
            light: .hex("#141414"),
            dark: .hex("#EDEDED")
        )
        // Secondary Text
        palette.secondaryForeground = .themed(
            light: .hex("#555555"),
            dark: .hex("#A0A0A0")
        )
        // Mechanical Divider & Borders
        palette.divider = .themed(
            light: .hex("#141414"),
            dark: .hex("#EBEBEB")
        )
        // Phosphor Volt Brand Accent
        palette.primary = .init(
            main: .universal(.hex("#19E58C")),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#E5E2D8"),
                dark: .hex("#202327")
            )
        )
        // Sky Blue Accent
        palette.accent = .init(
            main: .universal(.hex("#38BDF8")),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#E0F2FE"),
                dark: .hex("#1E293B")
            )
        )
        // Success Emerald
        palette.success = .init(
            main: .universal(.hex("#22C55E")),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#DCFCE7"),
                dark: .hex("#14532D")
            )
        )
        // Terminal Amber Warning
        palette.warning = .init(
            main: .universal(.hex("#FFA000")),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#FEF3C7"),
                dark: .hex("#451A03")
            )
        )
        // Phosphor Red Destructive
        palette.danger = .init(
            main: .universal(.hex("#FF3B30")),
            contrast: .universal(.hex("#FFFFFF")),
            background: .themed(
                light: .hex("#FEE2E2"),
                dark: .hex("#451A1A")
            )
        )

        var layout = Theme.Layout()
        layout.containerRadius = .init(small: 8, medium: 10, large: 14)
        layout.componentRadius = .init(small: 6, medium: 8, large: 10)
        layout.borderWidth = .init(small: 1.0, medium: 2.0, large: 2.5)

        // Physical 3D retro drop shadows: 0 blur radius, unblurred mechanical offset
        layout.shadow = .init(
            small: .init(
                radius: 0,
                offset: CGSize(width: 2, height: 2),
                color: .themed(
                    light: .rgba(r: 20, g: 20, b: 20, a: 1.0),
                    dark: .rgba(r: 235, g: 235, b: 235, a: 0.95)
                )
            ),
            medium: .init(
                radius: 0,
                offset: CGSize(width: 3, height: 3),
                color: .themed(
                    light: .rgba(r: 20, g: 20, b: 20, a: 1.0),
                    dark: .rgba(r: 235, g: 235, b: 235, a: 0.95)
                )
            ),
            large: .init(
                radius: 0,
                offset: CGSize(width: 5, height: 5),
                color: .themed(
                    light: .rgba(r: 20, g: 20, b: 20, a: 1.0),
                    dark: .rgba(r: 235, g: 235, b: 235, a: 0.95)
                )
            )
        )

        Theme.current.colors = palette
        Theme.current.layout = layout
    }
}

// MARK: - ComponentsKit Official SwiftUI Component Extensions

extension SUCard {
    /// Convenience initializer using ComponentsKit's Theme engine
    public init(
        cornerRadius: ContainerRadius = .medium,
        padding: CGFloat = 16,
        isTappable: Bool = false,
        backgroundColor: UniversalColor? = .secondaryBackground,
        borderColor: UniversalColor = .divider,
        borderWidth: BorderWidth = .medium,
        shadow: Shadow = .medium,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            model: CardVM {
                $0.cornerRadius = cornerRadius
                $0.contentPaddings = .init(padding: padding)
                $0.backgroundColor = backgroundColor
                $0.borderColor = borderColor
                $0.borderWidth = borderWidth
                $0.shadow = shadow
                $0.isTappable = isTappable
            },
            content: content,
            onTap: onTap
        )
    }
}

extension SUBadge {
    /// Convenience initializer for retro status badges
    public init(
        _ title: String,
        color: ComponentColor = .primary,
        style: BadgeVM.Style = .filled
    ) {
        self.init(model: BadgeVM {
            $0.title = title.uppercased()
            $0.color = color
            $0.style = style
            $0.cornerRadius = .small
            $0.font = .system(size: 11, weight: .bold)
            $0.paddings = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        })
    }
}

extension SUButton {
    /// Convenience initializer for standard and full-width ComponentsKit buttons
    public init(
        title: String,
        color: ComponentColor? = .primary,
        style: ComponentsKit.ButtonStyle = .filled,
        size: ComponentSize = .medium,
        isFullWidth: Bool = true,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            model: ButtonVM {
                $0.title = title
                $0.color = color
                $0.style = style
                $0.size = size
                $0.isFullWidth = isFullWidth
                $0.isEnabled = isEnabled
            },
            action: action
        )
    }
}

extension SUProgressBar {
    /// Convenience initializer for striped retro progress meters
    public init(
        value: CGFloat,
        max: CGFloat = 100,
        style: ProgressBarVM.Style = .striped,
        color: ComponentColor = .primary,
        size: ComponentSize = .medium
    ) {
        self.init(model: ProgressBarVM {
            $0.currentValue = value
            $0.maxValue = max
            $0.style = style
            $0.color = color
            $0.size = size
            $0.cornerRadius = .small
        })
    }
}

// MARK: - ComponentsKit Official Transition Adapters

/// RetroCard powered by ComponentsKit SUCard
public struct RetroCard<Content: View>: View {
    public let cornerRadius: ContainerRadius
    public let padding: CGFloat
    public let isTappable: Bool
    public let onTap: () -> Void
    public let content: () -> Content

    public init(
        cornerRadius: CGFloat = 10,
        padding: CGFloat = 16,
        isTappable: Bool = false,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = .custom(cornerRadius)
        self.padding = padding
        self.isTappable = isTappable
        self.onTap = onTap
        self.content = content
    }

    public var body: some View {
        SUCard(
            model: CardVM {
                $0.cornerRadius = cornerRadius
                $0.contentPaddings = .init(padding: padding)
                $0.backgroundColor = .secondaryBackground
                $0.borderColor = .divider
                $0.borderWidth = .medium
                $0.shadow = .medium
                $0.isTappable = isTappable
            },
            content: content,
            onTap: onTap
        )
    }
}

/// RetroBadge powered by ComponentsKit SUBadge
public struct RetroBadge: View {
    public let text: String
    public let color: ComponentColor
    public let isFilled: Bool

    public init(_ text: String, color: ComponentColor = .primary, isFilled: Bool = false) {
        self.text = text
        self.color = color
        self.isFilled = isFilled
    }

    public init(_ text: String, color: Color, isFilled: Bool = false) {
        self.text = text
        self.color = .primary
        self.isFilled = isFilled
    }

    public var body: some View {
        SUBadge(model: BadgeVM {
            $0.title = text.uppercased()
            $0.color = color
            $0.style = isFilled ? .filled : .light
            $0.cornerRadius = .small
            $0.font = .system(size: 11, weight: .bold)
            $0.paddings = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        })
    }
}

/// RetroBlockMeter powered by ComponentsKit SUProgressBar (.striped)
public struct RetroBlockMeter: View {
    public let filled: Int
    public let total: Int
    public let color: ComponentColor

    public init(filled: Int = 12, total: Int = 16, color: ComponentColor = .primary) {
        self.filled = filled
        self.total = total
        self.color = color
    }

    public init(filled: Int = 12, total: Int = 16, color: Color) {
        self.filled = filled
        self.total = total
        self.color = .primary
    }

    public var body: some View {
        SUProgressBar(model: ProgressBarVM {
            $0.currentValue = CGFloat(filled)
            $0.maxValue = CGFloat(total)
            $0.style = .striped
            $0.color = color
            $0.size = .small
            $0.cornerRadius = .small
        })
    }
}

/// RetroButtonStyle powered by ComponentsKit Theme layout and borders
public struct RetroButtonStyle: SwiftUI.ButtonStyle {
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
                    .stroke(UniversalColor.divider.color, lineWidth: Theme.current.layout.borderWidth.medium)
            )
            .shadow(
                color: Theme.current.layout.shadow.medium.color.color,
                radius: 0,
                x: configuration.isPressed ? 0 : 3,
                y: configuration.isPressed ? 0 : 3
            )
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
