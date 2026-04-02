//
//  DashboardViewModel.swift
//  UpSelf
//
//  Presentation logic for the HUD; routing stays in AppCoordinator.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {

    private let modelContext: ModelContext

    /// Set by `AppCoordinator` to present the attribute picker as a UIKit sheet.
    var onPresentQuestCompletion: (([CharacterStat]) -> Void)?

    /// Set by `AppCoordinator` to dismiss the quest completion sheet after XP is saved.
    var onDismissQuestCompletion: (() -> Void)?

    /// Set by `AppCoordinator` to present the create-quest sheet.
    var onPresentCreateQuest: (() -> Void)?

    /// Set by `AppCoordinator` to push the activity log screen.
    var onPresentHistoryLog: (() -> Void)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func completeQuest(stats: [CharacterStat]) {
        onPresentQuestCompletion?(stats)
    }

    func presentCreateQuest() {
        onPresentCreateQuest?()
    }

    func presentHistoryLog() {
        onPresentHistoryLog?()
    }

    func addXP(to stat: CharacterStat, tier: QuestRewardTier = .easy) {
        let delta = tier.xp
        stat.currentXP += delta
        do {
            ActivityLogService.insertXPGain(context: modelContext, stat: stat, tier: tier)
            try modelContext.save()
            onDismissQuestCompletion?()
        } catch {
            stat.currentXP -= delta
        }
    }
}
