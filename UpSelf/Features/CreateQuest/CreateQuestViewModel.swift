//
//  CreateQuestViewModel.swift
//  UpSelf
//
//  Presentation logic for authoring a SwiftData `Quest`; routing stays in AppCoordinator.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class CreateQuestViewModel {

    private let modelContext: ModelContext
    private let onDismiss: () -> Void

    var titleText: String = ""
    var selectedTier: QuestRewardTier = .easy
    var selectedAttribute: CharacterAttribute = .logistics
    var isDaily: Bool = true
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
            let quest = Quest(
                title: trimmed,
                statKind: selectedAttribute,
                rewardXP: selectedTier.xp,
                isDaily: isDaily
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
