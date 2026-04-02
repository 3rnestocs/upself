//
//  CharacterAttribute.swift
//  UpSelf
//
//  Canonical stat kinds (persisted by `rawValue`, displayed via String Catalog).
//

import Foundation

/// The six RPG attributes. Raw values are stable English identifiers for SwiftData / sync.
enum CharacterAttribute: String, CaseIterable, Codable, Sendable {
    case logistics
    case mastery
    case charisma
    case willpower
    case vitality
    case economy

    /// Normalizes legacy DB values (Spanish labels or older seeds) to `rawValue`.
    static func normalizedStorage(_ stored: String) -> String {
        if CharacterAttribute(rawValue: stored) != nil { return stored }
        switch stored {
        case "Logística": return CharacterAttribute.logistics.rawValue
        case "Maestría": return CharacterAttribute.mastery.rawValue
        case "Carisma": return CharacterAttribute.charisma.rawValue
        case "Voluntad": return CharacterAttribute.willpower.rawValue
        case "Vitalidad": return CharacterAttribute.vitality.rawValue
        case "Economía": return CharacterAttribute.economy.rawValue
        default: return CharacterAttribute.logistics.rawValue
        }
    }
}
