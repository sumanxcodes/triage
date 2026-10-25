import SwiftUI
import UIKit
import ComponentsKit

// MARK: - ComponentsKit Official Theme Engine

public struct RetroTheme {
    /// Canvas Background: Soft retro canvas #F3F1EB in Light Mode, #0C0D0E in Dark Mode
    public static var background: Color { UniversalColor.background.color }

    /// Card Surface: Exact warm retro cream #FEF3E0 in Light Mode, #25221B in Dark Mode
    public static var surface: Color { UniversalColor.accentBackground.color }

    /// Elevated Surface for sub-components, inputs, and chips
    public static var elevatedSurface: Color { UniversalColor.content1.color }

    /// Retro Solid Line Border / Divider: #E2D8C6 in Light Mode, #38342C in Dark Mode
    public static var border: Color { UniversalColor.divider.color }

    /// Soft ambient drop shadow matching the ComponentsKit Medium shadow preset
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

    /// Configures ComponentsKit's global theme engine with the exact attributes and colors
    public static func configureComponentsKit() {
        var palette = Theme.Palette()

        // Canvas Background: #F3F1EB (Light) / #0C0D0E (Dark)
        palette.background = .themed(
            light: .hex("#F3F1EB"),
            dark: .hex("#0C0D0E")
        )

        // Card Surface / Secondary Background: #FEF3E0 (Light) / #25221B (Dark)
        palette.secondaryBackground = .themed(
            light: .hex("#FEF3E0"),
            dark: .hex("#25221B")
        )

        // Accent with warm cream background as displayed in ComponentsKit demo
        palette.accent = .init(
            main: .universal(.hex("#E29A38")),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#FEF3E0"),
                dark: .hex("#25221B")
            )
        )

        // Sub-elements / elevated chips
        palette.content1 = .themed(
            light: .hex("#F3E6D0"),
            dark: .hex("#2E2920")
        )
        palette.content2 = .themed(
            light: .hex("#E8D8BF"),
            dark: .hex("#3B3428")
        )

        // Primary Text: High-contrast #141414 in Light Mode, Crisp #EDEDED in Dark Mode
        palette.foreground = .themed(
            light: .hex("#141414"),
            dark: .hex("#EDEDED")
        )

        // Secondary Text: Muted warm gray #595959 in Light Mode, #A0A0A0 in Dark Mode
        palette.secondaryForeground = .themed(
            light: .hex("#595959"),
            dark: .hex("#A0A0A0")
        )

        // Border & Divider: #E2D8C6 in Light Mode, #38342C in Dark Mode
        palette.divider = .themed(
            light: .hex("#E2D8C6"),
            dark: .hex("#38342C")
        )

        // Phosphor Volt Brand Accent (#19E58C)
        palette.primary = .init(
            main: .universal(.hex("#19E58C")),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#E5E2D8"),
                dark: .hex("#202327")
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
        layout.borderWidth = .init(small: 0.5, medium: 1.0, large: 2.0)

        // Medium shadow configured with subtle natural elevation matching the preview
        layout.shadow = .init(
            small: .init(
                radius: 4,
                offset: CGSize(width: 0, height: 2),
                color: .themed(
                    light: .rgba(r: 180, g: 160, b: 130, a: 0.18),
                    dark: .rgba(r: 0, g: 0, b: 0, a: 0.35)
                )
            ),
            medium: .init(
                radius: 6,
                offset: CGSize(width: 0, height: 3),
                color: .themed(
                    light: .rgba(r: 180, g: 160, b: 130, a: 0.25),
                    dark: .rgba(r: 0, g: 0, b: 0, a: 0.45)
                )
            ),
            large: .init(
                radius: 12,
                offset: CGSize(width: 0, height: 6),
                color: .themed(
                    light: .rgba(r: 180, g: 160, b: 130, a: 0.35),
                    dark: .rgba(r: 0, g: 0, b: 0, a: 0.55)
                )
            )
        )

        Theme.current.colors = palette
        Theme.current.layout = layout
    }
}

// MARK: - ComponentsKit Card Model Presets

extension CardVM {
    /// CardVM configured with the EXACT attributes from the ComponentsKit Card demo:
    /// - Animation Scale: Medium
    /// - Background Color: Accent Background
    /// - Background Style: Solid
    /// - Border Color: Divider
    /// - Border Width: Medium
    /// - Content Padding: 16px
    /// - Corner Radius: Medium
    /// - Shadow: Medium
    /// - Tappable: false
    public static var configured: CardVM {
        CardVM {
            $0.animationScale = .medium
            $0.backgroundColor = .accentBackground
            $0.backgroundStyle = .solid
            $0.borderColor = .divider
            $0.borderWidth = .medium
            $0.contentPaddings = .init(padding: 16)
            $0.cornerRadius = .medium
            $0.shadow = .medium
            $0.isTappable = false
        }
    }

    /// CardVM configured with the exact attributes, with optional tap interactivity
    public static func configured(
        isTappable: Bool = false,
        padding: CGFloat = 16,
        cornerRadius: ContainerRadius = .medium
    ) -> CardVM {
        CardVM {
            $0.animationScale = .medium
            $0.backgroundColor = .accentBackground
            $0.backgroundStyle = .solid
            $0.borderColor = .divider
            $0.borderWidth = .medium
            $0.contentPaddings = .init(padding: padding)
            $0.cornerRadius = cornerRadius
            $0.shadow = .medium
            $0.isTappable = isTappable
        }
    }
}

// MARK: - ComponentsKit Official SwiftUI Component Extensions

extension SUCard {
    /// Initializer using the exact Card attributes:
    /// - Animation Scale: Medium
    /// - Background Color: Accent Background
    /// - Background Style: Solid
    /// - Border Color: Divider
    /// - Border Width: Medium
    /// - Content Padding: 16px
    /// - Corner Radius: Medium
    /// - Shadow: Medium
    /// - Tappable: false (or specified)
    public init(
        isTappable: Bool = false,
        padding: CGFloat = 16,
        cornerRadius: ContainerRadius = .medium,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            model: CardVM.configured(
                isTappable: isTappable,
                padding: padding,
                cornerRadius: cornerRadius
            ),
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

/// RetroCard powered by ComponentsKit SUCard with the exact attributes
public struct RetroCard<Content: View>: View {
    public let model: CardVM
    public let onTap: () -> Void
    public let content: () -> Content

    public init(
        cornerRadius: CGFloat = 10,
        padding: CGFloat = 16,
        isTappable: Bool = false,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.model = CardVM.configured(
            isTappable: isTappable,
            padding: padding,
            cornerRadius: .custom(cornerRadius)
        )
        self.onTap = onTap
        self.content = content
    }

    public init(
        model: CardVM = .configured,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.model = model
        self.onTap = onTap
        self.content = content
    }

    public var body: some View {
        SUCard(model: model, content: content, onTap: onTap)
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
                radius: 4,
                x: 0,
                y: 2
            )
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
