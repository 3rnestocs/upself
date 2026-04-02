//
//  QuestRewardTier.swift
//  UpSelf
//
//  Quest difficulty tiers. Persist `rewardXP` on `Quest` as these integers (progress units).
//  Weights satisfy 5×easy = 3×regular = 2×hard = 1×epic toward the first level segment (30).
//

import Foundation

enum QuestRewardTier: String, CaseIterable, Codable, Sendable {
    case easy
    case regular
    case hard
    case epic

    var xp: Int {
        switch self {
        case .easy: 6
        case .regular: 10
        case .hard: 15
        case .epic: 30
        }
    }

    init?(xp: Int) {
        guard let match = QuestRewardTier.allCases.first(where: { $0.xp == xp }) else { return nil }
        self = match
    }
}
