//
//  QuestRewardTier.swift
//  UpSelf
//
//  Static XP tiers for quests (S / M / L / XL). Persist `rewardXP` on `Quest`; use this enum when creating or interpreting rows.
//

import Foundation

enum QuestRewardTier: String, CaseIterable, Codable, Sendable {
    case small
    case medium
    case large
    case extraLarge

    var xp: Int {
        switch self {
        case .small: 10
        case .medium: 25
        case .large: 50
        case .extraLarge: 250
        }
    }

    init?(xp: Int) {
        guard let match = QuestRewardTier.allCases.first(where: { $0.xp == xp }) else { return nil }
        self = match
    }
}
