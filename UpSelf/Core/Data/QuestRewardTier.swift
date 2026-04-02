//
//  QuestRewardTier.swift
//  UpSelf
//
//  Static XP tiers for quests (S / M / L / XL). Persist `rewardXP` on `Quest`; use this enum when creating or interpreting rows.
//

import Foundation

enum QuestRewardTier: String, CaseIterable, Codable, Sendable {
    case easy
    case regular
    case hard
    case epic

    var xp: Int {
        switch self {
        case .easy: 10
        case .regular: 25
        case .hard: 50
        case .epic: 250
        }
    }

    init?(xp: Int) {
        guard let match = QuestRewardTier.allCases.first(where: { $0.xp == xp }) else { return nil }
        self = match
    }
}
