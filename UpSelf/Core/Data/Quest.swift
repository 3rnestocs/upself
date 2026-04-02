//
//  Quest.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//


import Foundation
import SwiftData

@Model
final class Quest {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Persisted `CharacterAttribute.rawValue` (column historically named `statType`).
    @Attribute(originalName: "statType") var statKindRawValue: String
    /// Prefer `QuestRewardTier.xp` when assigning; values 10 / 25 / 50 / 250 are the canonical tiers.
    var rewardXP: Int
    var isDaily: Bool
    var lastCompleted: Date?
    
    var user: UserProfile?

    var statKind: CharacterAttribute? {
        CharacterAttribute(rawValue: statKindRawValue)
    }

    var rewardTier: QuestRewardTier? {
        QuestRewardTier(xp: rewardXP)
    }

    init(id: UUID = UUID(),
         title: String,
         statKind: CharacterAttribute,
         rewardXP: Int = QuestRewardTier.easy.xp,
         isDaily: Bool = true) {
        self.id = id
        self.title = title
        self.statKindRawValue = statKind.rawValue
        self.rewardXP = rewardXP
        self.isDaily = isDaily
    }
}
