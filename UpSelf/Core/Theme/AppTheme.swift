//
//  AppTheme.swift
//  UpSelf
//
//  Central UI tokens: Amber Terminal theme (see plan.md).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && !canImport(UIKit)
import AppKit
#endif

/// Single place for colors, typography, spacing, and shape constants used across SwiftUI.
enum AppTheme {

    enum Colors {
        /// Main screen background — `#121212`
        static let background = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
        /// Card surfaces — `#242424`
        static let card = Color(red: 36 / 255, green: 36 / 255, blue: 36 / 255)
        /// XP / accent — `#FFB000`
        static let accentXP = Color(red: 255 / 255, green: 176 / 255, blue: 0 / 255)
        /// Primary CTA fill (same amber as `accentXP`); pair with `background` for label text.
        static let amber = accentXP
        /// HP / danger — `#FF4500`
        static let alertHP = Color(red: 255 / 255, green: 69 / 255, blue: 0 / 255)
        /// Secondary label on dark surfaces
        static let secondaryLabel = Color.white.opacity(0.65)
        /// Hairline borders on cards
        static let cardStroke = Color.white.opacity(0.12)
        /// Activity log: attribute line under XP / quest (distinct from date + accent XP line)
        static let activityLogStatLine = Color.white.opacity(0.62)
    }

    enum Fonts {
        /// PostScript names — must match the fonts listed under `UIAppFonts` / Font Book.
        private enum Quantico {
            static let regular = "Quantico-Regular"
            static let bold = "Quantico-Bold"
        }

        /// Quantico Regular — labels, titles, body copy.
        static func ui(_ style: Font.TextStyle = .body) -> Font {
            quantico(Quantico.regular, style: style)
        }

        /// Quantico Regular at a fixed point size, bypassing TextStyle ceiling.
        static func ui(size: CGFloat) -> Font {
            Font.custom(Quantico.regular, size: size)
        }

        /// Quantico Bold — numbers, stats, HP/XP (replaces monospaced emphasis).
        static func mono(_ style: Font.TextStyle = .body) -> Font {
            quantico(Quantico.bold, style: style)
        }

        /// Quantico Bold at a fixed point size, bypassing TextStyle ceiling.
        static func mono(size: CGFloat) -> Font {
            Font.custom(Quantico.bold, size: size)
        }

        private static func quantico(_ name: String, style: Font.TextStyle) -> Font {
            let size = preferredPointSize(for: style)
            return Font.custom(name, size: size, relativeTo: style)
        }

        private static func preferredPointSize(for style: Font.TextStyle) -> CGFloat {
            #if canImport(UIKit)
            return UIFont.preferredFont(forTextStyle: style.uiKitTextStyle).pointSize
            #elseif canImport(AppKit)
            return NSFont.preferredFont(forTextStyle: style.appKitTextStyle, options: [:]).pointSize
            #else
            return fallbackPointSize(for: style)
            #endif
        }

        private static func fallbackPointSize(for style: Font.TextStyle) -> CGFloat {
            switch style {
            case .largeTitle: return 34
            case .title: return 28
            case .title2: return 22
            case .title3: return 20
            case .headline: return 17
            case .body: return 17
            case .callout: return 16
            case .subheadline: return 15
            case .footnote: return 13
            case .caption: return 12
            case .caption2: return 11
            @unknown default: return 17
            }
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        /// Extra trailing space below each activity log block (terminal readability).
        static let logEntryBottom: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 12
        static let bar: CGFloat = 8
        static let chip: CGFloat = 6
    }

    enum Stroke {
        static let cardLine: CGFloat = 1
    }

    enum Bar {
        static let hpHeight: CGFloat = 28
        static let xpHeight: CGFloat = 6
    }

    /// Low-HP heartbeat on the HUD bar fill (HP ratio below `LockdownPolicy.heartbeatHPRatio`).
    enum HPHeartbeat {
        static let pulseDuration: Double = 1.15
        static let fillMinOpacity: CGFloat = 0.55
        static let fillMaxOpacity: CGFloat = 1.0
    }

    enum Shadow {
        static let cardRadius: CGFloat = 8
        static let cardY: CGFloat = 2
    }

    /// A type-safe icon reference — either an SF Symbol or an asset-catalog image.
    enum Icon {
        case symbol(String)
        case asset(String)

        /// Renders the icon as a SwiftUI view.
        /// - Parameters:
        ///   - size: Point size for symbols; width/height frame for assets.
        ///   - color: Tint applied to symbols (ignored for assets).
        @ViewBuilder
        func view(size: CGFloat = 24, color: Color = AppTheme.Colors.accentXP) -> some View {
            switch self {
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: size, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
    }

    /// Canonical icon mappings for domain types and app assets.
    enum Icons {
        static let appLogo: Icon = .asset("logo")

        // Onboarding
        static let onboardingWelcome: Icon        = .symbol("wand.and.sparkles")
        static let onboardingConcept: Icon        = .symbol("list.bullet.clipboard.fill")
        static let onboardingLockdown: Icon       = .symbol("lock.shield.fill")
        static let onboardingPersonalization: Icon = .symbol("scope")
        static let onboardingDifficulty: Icon     = .symbol("scale.3d")

        static func icon(for attribute: CharacterAttribute) -> Icon {
            switch attribute {
            case .vitality:  .symbol("heart.fill")
            case .mastery:   .symbol("book.fill")
            case .charisma:  .symbol("person.2.fill")
            case .willpower: .symbol("bolt.fill")
            case .logistics: .symbol("checklist")
            case .economy:   .symbol("dollarsign")
            }
        }
    }

}

#if canImport(UIKit)
private extension Font.TextStyle {
    var uiKitTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}
#endif

#if canImport(AppKit) && !canImport(UIKit)
private extension Font.TextStyle {
    var appKitTextStyle: NSFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}
#endif
