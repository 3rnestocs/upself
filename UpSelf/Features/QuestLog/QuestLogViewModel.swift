//
//  QuestLogViewModel.swift
//  UpSelf
//
//  Quest list and completion; navigation stays in AppCoordinator.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class QuestLogViewModel {

    private let modelContext: ModelContext
    private let gameClock: GameClock

    init(modelContext: ModelContext, gameClock: GameClock) {
        self.modelContext = modelContext
        self.gameClock = gameClock
    }

    /// Awards XP for this quest’s tier, logs activity, sets `lastCompleted` (per calendar day for dailies).
    func completePersistedQuest(_ quest: Quest) {
        let ref = gameClock.now
        guard quest.canComplete(referenceDate: ref) else { return }
        guard let attribute = quest.statKind,
              let profile = quest.user,
              let stat = profile.stats.first(where: { $0.kindRawValue == attribute.rawValue })
        else { return }

        let tier = QuestRewardTier(xp: quest.rewardXP) ?? .easy
        let delta = tier.xp
        let previousCompleted = quest.lastCompleted

        stat.currentXP += delta
        ActivityLogService.insertQuestXPGain(
            context: modelContext,
            stat: stat,
            tier: tier,
            questTitle: quest.title
        )
        quest.lastCompleted = ref

        do {
            try modelContext.save()
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        } catch {
            stat.currentXP -= delta
            quest.lastCompleted = previousCompleted
        }
    }
}
