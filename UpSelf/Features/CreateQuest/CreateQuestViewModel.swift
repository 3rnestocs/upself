//
//  CreateQuestViewModel.swift
//  UpSelf
//
//  Presentation logic for authoring a SwiftData `Quest`; routing stays in AppCoordinator.
//

import Foundation
import SwiftData

enum CreateQuestSchedule: String, CaseIterable, Identifiable {
    case committed = "committed"
    case freeform  = "freeform"
    case goal      = "goal"

    var id: String { rawValue }

    /// Default weeklyTarget when the user picks this schedule.
    var defaultWeeklyTarget: Int { 7 }
}

@MainActor
@Observable
final class CreateQuestViewModel {

    private let modelContext: ModelContext
    private let onDismiss: () -> Void

    var titleText: String = ""
    var selectedTier: QuestRewardTier = .easy
    var selectedAttribute: CharacterAttribute = .logistics
    var selectedSchedule: CreateQuestSchedule = .committed
    /// Only meaningful when `selectedSchedule == .committed`. Range 1…7.
    var weeklyTarget: Int = 7
    var validationMessage: LocalizedStringResource?

    init(modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        self.modelContext = modelContext
        self.onDismiss = onDismiss
    }

    func cancel() {
        onDismiss()
    }

    func save() {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = L10n.CreateQuest.validationTitleEmpty
            return
        }
        validationMessage = nil

        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1

        do {
            guard let profile = try modelContext.fetch(descriptor).first else {
                validationMessage = L10n.CreateQuest.validationNoProfile
                return
            }
            let resolvedWeeklyTarget: Int?
            let resolvedIsGoal: Bool
            switch selectedSchedule {
            case .committed:
                resolvedWeeklyTarget = weeklyTarget
                resolvedIsGoal = false
            case .freeform:
                resolvedWeeklyTarget = nil
                resolvedIsGoal = false
            case .goal:
                resolvedWeeklyTarget = nil
                resolvedIsGoal = true
            }

            let quest = Quest(
                title: trimmed,
                statKind: selectedAttribute,
                rewardXP: selectedTier.xp,
                weeklyTarget: resolvedWeeklyTarget,
                isGoal: resolvedIsGoal
            )
            quest.user = profile
            modelContext.insert(quest)
            try modelContext.save()
            onDismiss()
        } catch {
            validationMessage = L10n.CreateQuest.validationSaveFailed
        }
    }
}
