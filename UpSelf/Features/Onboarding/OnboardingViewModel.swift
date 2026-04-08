//
//  OnboardingViewModel.swift
//  UpSelf
//
//  Drives the onboarding flow: selects starter quests and imports them on completion.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class OnboardingViewModel {

    private let modelContext: ModelContext
    private let importService: BundledQuestImportServiceProtocol

    var isImporting: Bool = false
    var importError: String? = nil

    init(
        modelContext: ModelContext,
        importService: BundledQuestImportServiceProtocol = BundledQuestImportService()
    ) {
        self.modelContext = modelContext
        self.importService = importService
    }

    /// Imports the personalised starter quest set. Call from the final onboarding step.
    /// - Parameter priority: Stat chosen on the personalisation screen; `nil` imports the base set.
    /// No-ops if the quests were already seeded (e.g. app killed before onboarding completed).
    func importStarterQuests(priority: CharacterAttribute? = nil) {
        guard !UserDefaults.standard.bool(forKey: "hasSeededStarterQuests") else { return }

        isImporting = true
        importError = nil

        do {
            var descriptor = FetchDescriptor<UserProfile>()
            descriptor.fetchLimit = 1
            guard let profile = try modelContext.fetch(descriptor).first else {
                importError = "Profile not found."
                isImporting = false
                return
            }
            let blueprints = StarterQuestSelector.starterBlueprints(priority: priority)
            try importService.importBlueprints(blueprints, context: modelContext, profile: profile)
            UserDefaults.standard.set(true, forKey: "hasSeededStarterQuests")
        } catch {
            importError = error.localizedDescription
        }

        isImporting = false
    }
}
