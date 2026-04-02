//
//  CharacterStat.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//


import Foundation
import SwiftData

@Model
final class CharacterStat {
    @Attribute(.unique) var id: UUID
    /// Persisted `CharacterAttribute.rawValue` (column historically named `name`).
    @Attribute(originalName: "name") var kindRawValue: String
    var currentXP: Int

    var kind: CharacterAttribute? {
        CharacterAttribute(rawValue: kindRawValue)
    }
    
    var level: Int {
        let baseXP = 50.0
        let multiplier = 1.05
        if currentXP <= 0 { return 1 }
        let lvl = log(Double(currentXP) / baseXP) / log(multiplier) + 1
        return max(1, Int(lvl))
    }
    
    var user: UserProfile?

    init(id: UUID = UUID(), kind: CharacterAttribute, currentXP: Int = 0) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.currentXP = currentXP
    }
}
