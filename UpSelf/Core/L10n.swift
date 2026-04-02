//
//  L10n.swift
//  UpSelf
//
//  Strongly-typed access to `Localizable.xcstrings`. Views and ViewModels must use
//  `L10n` only — never `String(localized: "…")` or ad hoc string keys in UI code.
//

import Foundation

/// Central namespace for localized copy. Keys mirror `Localizable.xcstrings`.
enum L10n {

    enum App {
        static let title = LocalizedStringResource("app.title")
    }

    enum Common {
        static let placeholder = LocalizedStringResource("common.placeholder")
    }

    enum HUD {
        static let hpLabel = LocalizedStringResource("hud.hp.label")
        static let attributesTitle = LocalizedStringResource("hud.attributes.title")
        static let completeQuest = LocalizedStringResource("hud.complete_quest")

        static func hpPair(current: Int, max: Int) -> String {
            String(localized: "hp.pair \(current) \(max)")
        }

        static func levelFormat(level: Int) -> String {
            String(localized: "hud.level.format \(level)")
        }

        static func xpFormat(xp: Int) -> String {
            String(localized: "hud.xp.format \(xp)")
        }
    }

    enum Stats {
        static let unknown = LocalizedStringResource("stat.unknown")

        static let logistics = LocalizedStringResource("stat.logistics")
        static let mastery = LocalizedStringResource("stat.mastery")
        static let charisma = LocalizedStringResource("stat.charisma")
        static let willpower = LocalizedStringResource("stat.willpower")
        static let vitality = LocalizedStringResource("stat.vitality")
        static let economy = LocalizedStringResource("stat.economy")

        static func title(for attribute: CharacterAttribute) -> LocalizedStringResource {
            switch attribute {
            case .logistics: logistics
            case .mastery: mastery
            case .charisma: charisma
            case .willpower: willpower
            case .vitality: vitality
            case .economy: economy
            }
        }
    }

    enum Accessibility {
        static var xpProgress: String {
            String(localized: "accessibility.xp_progress")
        }

        static func xpPercent(_ percent: Int) -> String {
            String(localized: "accessibility.xp.percent \(percent)")
        }
    }

    enum Errors {
        static func modelContainer(_ error: Error) -> String {
            String(format: String(localized: "error.model_container"), String(describing: error))
        }
    }
}
