import SwiftUI
import UIKit
import ComponentsKit

import SwiftUI
import UIKit
import CoreText
import ComponentsKit

// MARK: - Dynamic Font Loader (CoreText Registration)

public enum FontLoader {
    private static var hasRegistered = false

    public static func registerFonts() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let fontFiles = [
            "Urbanist-Regular",
            "Urbanist-Medium",
            "Urbanist-SemiBold",
            "Urbanist-Semibold",
            "Urbanist-Bold"
        ]

        for name in fontFiles {
            if let fontURL = Bundle.main.url(forResource: name, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            }
        }

        if let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            for url in urls {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            }
        }
    }
}

// MARK: - ComponentsKit Modern Theme

extension Theme {
    public static let modern: Self = .init {
        $0.colors.background = .themed(
            light: .hex("F6F9FC"),
            dark: .hex("0A0B0D")
        )
        $0.colors.secondaryBackground = .themed(
            light: .hex("FFFFFF"),
            dark: .hex("1A1B1F")
        )
        $0.colors.foreground = .themed(
            light: .hex("0A2540"),
            dark: .hex("FFFFFF")
        )
        $0.colors.secondaryForeground = .themed(
            light: .hex("425466"),
            dark: .hex("BCCCDC")
        )
        $0.colors.content1 = .themed(
            light: .hex("E9F0FB"),
            dark: .hex("1C2C40")
        )
        $0.colors.content2 = .themed(
            light: .hex("D6E4F0"),
            dark: .hex("253B59")
        )
        $0.colors.content3 = .themed(
            light: .hex("B3C7E6"),
            dark: .hex("32537C")
        )
        $0.colors.content4 = .themed(
            light: .hex("8CA8D8"),
            dark: .hex("4D6BA3")
        )
        $0.colors.divider = .themed(
            light: .rgba(r: 10, g: 37, b: 64, a: 0.1),
            dark: .rgba(r: 255, g: 255, b: 255, a: 0.1)
        )
        $0.colors.accent = .init(
            main: .themed(
                light: .hex("635BFF"),
                dark: .hex("9E95FF")
            ),
            contrast: .themed(
                light: .hex("FFFFFF"),
                dark: .hex("0A0B0D")
            ),
            background: .themed(
                light: .hex("E7E5FF"),
                dark: .hex("3B388C")
            )
        )
        $0.colors.primary = .init(
            main: .themed(
                light: .hex("#0B0C0E"),
                dark: .hex("#FFFFFF")
            ),
            contrast: .themed(
                light: .hex("#FFFFFF"),
                dark: .hex("#0B0C0E")
            ),
            background: .themed(
                light: .hex("#D9D9D9"),
                dark: .hex("#515253")
            )
        )
        $0.colors.success = .init(
            main: .themed(
                light: .hex("00B86B"),
                dark: .hex("00D487")
            ),
            contrast: .themed(
                light: .hex("FFFFFF"),
                dark: .hex("0A0B0D")
            ),
            background: .themed(
                light: .hex("D8F5EC"),
                dark: .hex("1E3C34")
            )
        )
        $0.colors.warning = .init(
            main: .themed(
                light: .hex("FFB020"),
                dark: .hex("FFC94A")
            ),
            contrast: .universal(.hex("0A2540")),
            background: .themed(
                light: .hex("FFF4D6"),
                dark: .hex("4E3E1C")
            )
        )
        $0.colors.danger = .init(
            main: .themed(
                light: .hex("FF5A5F"),
                dark: .hex("FF7B84")
            ),
            contrast: .universal(.hex("FFFFFF")),
            background: .themed(
                light: .hex("FFEAEA"),
                dark: .hex("4A2C2C")
            )
        )
        $0.layout.disabledOpacity = 0.5
        $0.layout.componentRadius = .init(
            small: 8.0,
            medium: 12.0,
            large: 16.0
        )
        $0.layout.containerRadius = .init(
            small: 12.0,
            medium: 16.0,
            large: 20.0
        )
        $0.layout.shadow = .init(
            small: .init(
                radius: 6.0,
                offset: .init(width: 0, height: 4),
                color: .themed(
                    light: .rgba(r: 0, g: 0, b: 0, a: 0.08),
                    dark: .rgba(r: 255, g: 255, b: 255, a: 0.08)
                )
            ),
            medium: .init(
                radius: 12.0,
                offset: .init(width: 0, height: 6),
                color: .themed(
                    light: .rgba(r: 0, g: 0, b: 0, a: 0.12),
                    dark: .rgba(r: 255, g: 255, b: 255, a: 0.12)
                )
            ),
            large: .init(
                radius: 16.0,
                offset: .init(width: 0, height: 8),
                color: .themed(
                    light: .rgba(r: 0, g: 0, b: 0, a: 0.16),
                    dark: .rgba(r: 255, g: 255, b: 255, a: 0.16)
                )
            )
        )
        $0.layout.borderWidth = .init(
            small: 0.5,
            medium: 1.0,
            large: 2.0
        )
        $0.layout.animationScale = .init(
            small: 0.99,
            medium: 0.97,
            large: 0.95
        )
        $0.layout.typography.headline = .init(
            small: .custom(name: "Urbanist-Medium", size: 16),
            medium: .custom(name: "Urbanist-Semibold", size: 20),
            large: .custom(name: "Urbanist-Bold", size: 24)
        )
        $0.layout.typography.body = .init(
            small: .custom(name: "Urbanist-Regular", size: 14),
            medium: .custom(name: "Urbanist-Regular", size: 16),
            large: .custom(name: "Urbanist-Regular", size: 18)
        )
        $0.layout.typography.button = .init(
            small: .custom(name: "Urbanist-Medium", size: 14),
            medium: .custom(name: "Urbanist-Medium", size: 16),
            large: .custom(name: "Urbanist-Medium", size: 20)
        )
        $0.layout.typography.caption = .init(
            small: .custom(name: "Urbanist-Regular", size: 10),
            medium: .custom(name: "Urbanist-Regular", size: 12),
            large: .custom(name: "Urbanist-Regular", size: 14)
        )
    }
}

// MARK: - ComponentsKit Official Theme System

public typealias AppTheme = RetroTheme

public struct RetroTheme {
    // MARK: - 1. Backgrounds
    /// Primary Background: Main screen/page canvas (#F6F9FC in Light, #0A0B0D in Dark)
    public static var background: Color { UniversalColor.background.color }
    public static var bgPrimary: Color { UniversalColor.background.color }

    /// Secondary Background: Container wells & cards (#FFFFFF in Light, #1A1B1F in Dark)
    public static var secondaryBackground: Color { UniversalColor.secondaryBackground.color }
    public static var bgSecondary: Color { UniversalColor.secondaryBackground.color }

    /// Card Surface Background (#FFFFFF in Light, #1A1B1F in Dark)
    public static var surface: Color { UniversalColor.secondaryBackground.color }
    public static var cardBackground: Color { UniversalColor.secondaryBackground.color }
    public static var accentSurface: Color { UniversalColor.accentBackground.color }

    // MARK: - 2. Foregrounds
    /// Primary Foreground Text: Headings and titles (#0A2540 in Light, #FFFFFF in Dark)
    public static var foreground: Color { UniversalColor.foreground.color }
    public static var fgPrimary: Color { UniversalColor.foreground.color }

    /// Secondary Foreground Text: Subtitles and captions (#425466 in Light, #BCCCDC in Dark)
    public static var secondaryForeground: Color { UniversalColor.secondaryForeground.color }
    public static var fgSecondary: Color { UniversalColor.secondaryForeground.color }

    // MARK: - 3. Content
    /// Content 1: First content background / elevated badge / chip well (#E9F0FB in Light, #1C2C40 in Dark)
    public static var content1: Color { UniversalColor.content1.color }
    public static var elevatedSurface: Color { UniversalColor.content1.color }

    /// Content 2: Second content background (#D6E4F0 in Light, #253B59 in Dark)
    public static var content2: Color { UniversalColor.content2.color }

    /// Content 3: Third content background (#B3C7E6 in Light, #32537C in Dark)
    public static var content3: Color { UniversalColor.content3.color }

    /// Content 4: Fourth content background (#8CA8D8 in Light, #4D6BA3 in Dark)
    public static var content4: Color { UniversalColor.content4.color }

    /// Divider & Borders: Line separators and borders (rgba(10,37,64,0.1) in Light, rgba(255,255,255,0.1) in Dark)
    public static var divider: Color { UniversalColor.divider.color }
    public static var border: Color { UniversalColor.divider.color }

    /// Soft ambient drop shadow matching the ComponentsKit Medium shadow preset
    public static var shadow: Color { Theme.current.layout.shadow.medium.color.color }

    // MARK: - 4. Components
    /// Component: Primary (#0B0C0E in Light, #FFFFFF in Dark)
    public static var primary: Color { UniversalColor.primary.color }
    public static var primaryBackground: Color { UniversalColor.primaryBackground.color }
    public static var primaryContrast: Color { UniversalColor.primaryContrast.color }

    /// Component: Accent (#635BFF in Light, #9E95FF in Dark)
    public static var accent: Color { UniversalColor.accent.color }
    public static var accentBackground: Color { UniversalColor.accentBackground.color }
    public static var accentContrast: Color { UniversalColor.accentContrast.color }

    /// Component: Success (#00B86B in Light, #00D487 in Dark)
    public static var success: Color { UniversalColor.success.color }
    public static var successBackground: Color { UniversalColor.successBackground.color }
    public static var successContrast: Color { UniversalColor.successContrast.color }

    /// Component: Warning (#FFB020 in Light, #FFC94A in Dark)
    public static var warning: Color { UniversalColor.warning.color }
    public static var warningBackground: Color { UniversalColor.warningBackground.color }
    public static var warningContrast: Color { UniversalColor.warningContrast.color }

    /// Component: Danger (#FF5A5F in Light, #FF7B84 in Dark)
    public static var danger: Color { UniversalColor.danger.color }
    public static var dangerBackground: Color { UniversalColor.dangerBackground.color }
    public static var dangerContrast: Color { UniversalColor.dangerContrast.color }

    // Backward compatibility aliases
    public static var volt: Color { UniversalColor.primary.color }
    public static var textAccent: Color { UniversalColor.success.color }
    public static var amber: Color { UniversalColor.warning.color }
    public static var textAmber: Color { UniversalColor.warning.color }
    public static var red: Color { UniversalColor.danger.color }

    // MARK: - 5. Typography (Urbanist Font Family)
    public static var headlineSmall: Font { UniversalFont.smHeadline.font }
    public static var headlineMedium: Font { UniversalFont.mdHeadline.font }
    public static var headlineLarge: Font { UniversalFont.lgHeadline.font }

    public static var bodySmall: Font { UniversalFont.smBody.font }
    public static var bodyMedium: Font { UniversalFont.mdBody.font }
    public static var bodyLarge: Font { UniversalFont.lgBody.font }

    public static var buttonSmall: Font { UniversalFont.smButton.font }
    public static var buttonMedium: Font { UniversalFont.mdButton.font }
    public static var buttonLarge: Font { UniversalFont.lgButton.font }

    public static var captionSmall: Font { UniversalFont.smCaption.font }
    public static var captionMedium: Font { UniversalFont.mdCaption.font }
    public static var captionLarge: Font { UniversalFont.lgCaption.font }

    public static func urbanist(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = "Urbanist-Bold"
        case .semibold:
            fontName = "Urbanist-Semibold"
        case .medium:
            fontName = "Urbanist-Medium"
        default:
            fontName = "Urbanist-Regular"
        }
        return .custom(fontName, size: size)
    }

    /// Configures ComponentsKit's global theme engine with Theme.modern
    public static func configureComponentsKit() {
        FontLoader.registerFonts()
        Theme.current = .modern
    }
}

// MARK: - ComponentsKit Card Model Presets

extension CardVM {
    /// CardVM configured with the EXACT attributes from ComponentsKit Card specification:
    /// - Animation Scale: Medium
    /// - Background Color: Secondary Background
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
            $0.backgroundColor = .secondaryBackground
            $0.backgroundStyle = .solid
            $0.borderColor = .divider
            $0.borderWidth = .medium
            $0.contentPaddings = .init(padding: 16)
            $0.cornerRadius = .medium
            $0.shadow = .medium
            $0.isTappable = false
        }
    }

    /// CardVM configured with the exact attributes, with optional tap interactivity and custom background
    public static func configured(
        isTappable: Bool = false,
        padding: CGFloat = 16,
        cornerRadius: ContainerRadius = .medium,
        backgroundColor: UniversalColor? = .secondaryBackground
    ) -> CardVM {
        CardVM {
            $0.animationScale = .medium
            $0.backgroundColor = backgroundColor
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
    /// Convenience initializer for status badges
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
            $0.font = .custom(name: "Urbanist-Bold", size: 11)
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
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        isTappable: Bool = false,
        backgroundColor: UniversalColor? = .secondaryBackground,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.model = CardVM.configured(
            isTappable: isTappable,
            padding: padding,
            cornerRadius: .custom(cornerRadius),
            backgroundColor: backgroundColor
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

// MARK: - ComponentColor Extended Presets

extension ComponentColor {
    /// Secondary muted component tone
    public static var secondary: Self {
        .init(
            main: UniversalColor.secondaryForeground,
            contrast: UniversalColor.background,
            background: UniversalColor.content1
        )
    }

    /// Red tone aliased to danger
    public static var red: Self {
        .danger
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

    public var body: some View {
        SUBadge(model: BadgeVM {
            $0.title = text.uppercased()
            $0.color = color
            $0.style = isFilled ? .filled : .light
            $0.cornerRadius = .small
            $0.font = .custom(name: "Urbanist-Bold", size: 11)
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
        backgroundColor: Color = RetroTheme.primary,
        foregroundColor: Color = RetroTheme.primaryContrast,
        cornerRadius: CGFloat = 10
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Urbanist-Medium", size: 14))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(UniversalColor.divider.color, lineWidth: Theme.current.layout.borderWidth.small)
            )
            .shadow(
                color: Theme.current.layout.shadow.small.color.color,
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(configuration.isPressed ? Theme.current.layout.animationScale.medium : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
