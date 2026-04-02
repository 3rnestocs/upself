//
//  DashboardViewModel.swift
//  UpSelf
//
//  Presentation logic for the HUD; routing stays in AppCoordinator.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class DashboardViewModel {

    private let modelContext: ModelContext

    /// Set by `AppCoordinator` to present the create-quest sheet.
    var onPresentCreateQuest: (() -> Void)?

    /// Set by `AppCoordinator` to push the activity log screen.
    var onPresentHistoryLog: (() -> Void)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func presentCreateQuest() {
        onPresentCreateQuest?()
    }

    func presentHistoryLog() {
        onPresentHistoryLog?()
    }

    /// Awards XP for this quest’s tier, logs activity, sets `lastCompleted` (per calendar day for dailies).
    func completePersistedQuest(_ quest: Quest) {
        guard quest.canComplete() else { return }
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
        quest.lastCompleted = Date()

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
