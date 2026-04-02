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
}
