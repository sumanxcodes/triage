import SwiftUI
import UIKit
import ComponentsKit

// MARK: - ComponentsKit Official Theme Engine

public struct RetroTheme {
    /// Canvas Background: Soft retro canvas #F3F1EB in Light Mode, #090F0A in Dark Mode
    public static var background: Color { UniversalColor.background.color }

    /// Card Surface: Accent Background (#FEF3E0 in Light Mode, #4E2A1A in Dark Mode) as configured in ComponentsKit Demo
    public static var surface: Color { UniversalColor.accentBackground.color }

    /// Secondary Surface: #FEFDF6 in Light Mode, #101910 in Dark Mode
    public static var secondarySurface: Color { UniversalColor.secondaryBackground.color }

    /// Elevated Surface for sub-components, inputs, and chips (#FFEED0 in Light Mode, #142415 in Dark Mode)
    public static var elevatedSurface: Color { UniversalColor.content1.color }

    /// Retro Solid Line Border / Divider: #C2C0BD in Light Mode, #093F24 in Dark Mode
    public static var border: Color { UniversalColor.divider.color }

    /// Soft ambient drop shadow matching the ComponentsKit Medium shadow preset
    public static var shadow: Color { Theme.current.layout.shadow.medium.color.color }

    /// Phosphor Green Brand Accent (#19E58C in Light Mode, #02FF88 in Dark Mode)
    public static var volt: Color {
        UniversalColor.themed(light: .hex("#19E58C"), dark: .hex("#02FF88")).color
    }

    /// Terminal Text / Active Accent (#2C974B in Light Mode, #02FF88 in Dark Mode)
    public static var textAccent: Color {
        UniversalColor.themed(light: .hex("#2C974B"), dark: .hex("#02FF88")).color
    }

    /// Terminal Amber Warning Accent (#FEA800 in Light Mode, #FAD000 in Dark Mode)
    public static var amber: Color { UniversalColor.warning.color }

    /// Terminal Amber Text
    public static var textAmber: Color { UniversalColor.warning.color }

    /// Phosphor Red / Danger Accent (#FE0133 in Light Mode, #FF3960 in Dark Mode)
    public static var red: Color { UniversalColor.danger.color }

    /// Primary Foreground Text (#2C2C2C in Light Mode, #02FF88 in Dark Mode)
    public static var foreground: Color { UniversalColor.foreground.color }

    /// Secondary Foreground Text (#595959 in Light Mode, #66FFCC in Dark Mode)
    public static var secondaryForeground: Color { UniversalColor.secondaryForeground.color }

    /// Configures ComponentsKit's global theme engine with the exact Retro Theme Palette from the demo
    public static func configureComponentsKit() {
        var palette = Theme.Palette()

        // Background: #F3F1EB (Light) / #090F0A (Dark)
        palette.background = .themed(
            light: .hex("#F3F1EB"),
            dark: .hex("#090F0A")
        )

        // Secondary Background: #FEFDF6 (Light) / #101910 (Dark)
        palette.secondaryBackground = .themed(
            light: .hex("#FEFDF6"),
            dark: .hex("#101910")
        )

        // Foreground: Primary text #2C2C2C (Light) / Phosphor Green #02FF88 (Dark)
        palette.foreground = .themed(
            light: .hex("#2C2C2C"),
            dark: .hex("#02FF88")
        )

        // Secondary Foreground: Muted #595959 (Light) / Phosphor Mint #66FFCC (Dark)
        palette.secondaryForeground = .themed(
            light: .hex("#595959"),
            dark: .hex("#66FFCC")
        )

        // Content Swatches:
        // Content 1: #FFEED0 (Light) / #142415 (Dark)
        palette.content1 = .themed(
            light: .hex("#FFEED0"),
            dark: .hex("#142415")
        )

        // Content 2: #FED0DB (Light) / #1C1A1D (Dark)
        palette.content2 = .themed(
            light: .hex("#FED0DB"),
            dark: .hex("#1C1A1D")
        )

        // Content 3: #B2E0FE (Light) / #122032 (Dark)
        palette.content3 = .themed(
            light: .hex("#B2E0FE"),
            dark: .hex("#122032")
        )

        // Content 4: #D2F9D5 (Light) / #173A28 (Dark)
        palette.content4 = .themed(
            light: .hex("#D2F9D5"),
            dark: .hex("#173A28")
        )

        // Divider: #C2C0BD (Light) / #093F24 (Dark)
        palette.divider = .themed(
            light: .hex("#C2C0BD"),
            dark: .hex("#093F24")
        )

        // Component: Primary
        // Main: #000000 (Light) / #02FF88 (Dark)
        // Background: #FCD24D (Light) / #00442A (Dark)
        // Contrast: #FFFFFF (Light) / #000000 (Dark)
        palette.primary = .init(
            main: .themed(
                light: .hex("#000000"),
                dark: .hex("#02FF88")
            ),
            contrast: .themed(
                light: .hex("#FFFFFF"),
                dark: .hex("#000000")
            ),
            background: .themed(
                light: .hex("#FCD24D"),
                dark: .hex("#00442A")
            )
        )

        // Component: Accent
        // Main: #FF5E00 (Light & Dark)
        // Background: #FEF3E0 (Light) / #4E2A1A (Dark)
        // Contrast: #FFFFFF (Light & Dark)
        palette.accent = .init(
            main: .universal(.hex("#FF5E00")),
            contrast: .universal(.hex("#FFFFFF")),
            background: .themed(
                light: .hex("#FEF3E0"),
                dark: .hex("#4E2A1A")
            )
        )

        // Component: Success
        // Main: #2C974B (Light) / #4FFA7B (Dark)
        // Background: #E5FFE7 (Light) / #1C3F26 (Dark)
        // Contrast: #FFFFFF (Light) / #000000 (Dark)
        palette.success = .init(
            main: .themed(
                light: .hex("#2C974B"),
                dark: .hex("#4FFA7B")
            ),
            contrast: .themed(
                light: .hex("#FFFFFF"),
                dark: .hex("#000000")
            ),
            background: .themed(
                light: .hex("#E5FFE7"),
                dark: .hex("#1C3F26")
            )
        )

        // Component: Warning
        // Main: #FEA800 (Light) / #FAD000 (Dark)
        // Background: #FFF4D6 (Light) / #4B3A00 (Dark)
        // Contrast: #000000 (Light & Dark)
        palette.warning = .init(
            main: .themed(
                light: .hex("#FEA800"),
                dark: .hex("#FAD000")
            ),
            contrast: .universal(.hex("#000000")),
            background: .themed(
                light: .hex("#FFF4D6"),
                dark: .hex("#4B3A00")
            )
        )

        // Component: Danger
        // Main: #FE0133 (Light) / #FF3960 (Dark)
        // Background: #FEE4E5 (Light) / #4C1B1B (Dark)
        // Contrast: #FFFFFF (Light & Dark)
        palette.danger = .init(
            main: .themed(
                light: .hex("#FE0133"),
                dark: .hex("#FF3960")
            ),
            contrast: .universal(.hex("#FFFFFF")),
            background: .themed(
                light: .hex("#FEE4E5"),
                dark: .hex("#4C1B1B")
            )
        )

        var layout = Theme.Layout()
        layout.containerRadius = .init(small: 8, medium: 10, large: 14)
        layout.componentRadius = .init(small: 6, medium: 8, large: 10)
        layout.borderWidth = .init(small: 0.5, medium: 1.0, large: 2.0)

        // Shadow presets matching ComponentsKit demo
        layout.shadow = .init(
            small: .init(
                radius: 4,
                offset: CGSize(width: 0, height: 2),
                color: .themed(
                    light: .rgba(r: 0, g: 0, b: 0, a: 0.05),
                    dark: .rgba(r: 0, g: 0, b: 0, a: 0.30)
                )
            ),
            medium: .init(
                radius: 6,
                offset: CGSize(width: 0, height: 3),
                color: .themed(
                    light: .rgba(r: 0, g: 0, b: 0, a: 0.08),
                    dark: .rgba(r: 0, g: 0, b: 0, a: 0.40)
                )
            ),
            large: .init(
                radius: 12,
                offset: CGSize(width: 0, height: 6),
                color: .themed(
                    light: .rgba(r: 0, g: 0, b: 0, a: 0.12),
                    dark: .rgba(r: 0, g: 0, b: 0, a: 0.50)
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
