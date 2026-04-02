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
    /// Persisted `CharacterAttribute.rawValue`.
    var statKindRawValue: String
    /// Encodes `QuestRewardTier.xp` — canonical values **6 / 10 / 15 / 30** (progress units).
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

    // MARK: - Completion (calendar day = `Calendar.current` / user locale)

    /// Whether the row should read as “done”: dailies only when completed **today**; one-time forever after first completion.
    func displayAsCompleted(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let completed = lastCompleted else { return false }
        if isDaily {
            return calendar.isDate(completed, inSameDayAs: referenceDate)
        }
        return true
    }

    /// Whether the user can earn XP again for this quest right now.
    func canComplete(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        if isDaily {
            guard let completed = lastCompleted else { return true }
            return !calendar.isDate(completed, inSameDayAs: referenceDate)
        }
        return lastCompleted == nil
    }
}
