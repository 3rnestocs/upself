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
    /// Cumulative progress points toward levels (see `QuestRewardTier.xp` grants per quest).
    @Attribute(.unique) var id: UUID
    /// Persisted `CharacterAttribute.rawValue` (column historically named `name`).
    @Attribute(originalName: "name") var kindRawValue: String
    var currentXP: Int

    var kind: CharacterAttribute? {
        CharacterAttribute(rawValue: kindRawValue)
    }

    var level: Int {
        StatProgression.level(forTotalXP: currentXP)
    }

    /// 0…1 fill toward the next level threshold (aligned with `level`).
    var xpProgressFraction: CGFloat {
        CGFloat(StatProgression.progressFraction(forTotalXP: currentXP))
    }

    var user: UserProfile?

    init(id: UUID = UUID(), kind: CharacterAttribute, currentXP: Int = 0) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.currentXP = currentXP
    }
}
