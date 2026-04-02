//
//  ScreenTimeService.swift
//  UpSelf
//
//  Screen Time authorization and ManagedSettings shields (iOS / visionOS).
//

import Foundation

#if os(iOS) || os(visionOS)
import FamilyControls
import ManagedSettings

/// Authorizes Screen Time and applies / clears app shields via `ManagedSettingsStore`.
protocol ScreenTimeServiceProtocol: Sendable {
    func requestAuthorization() async throws
    func applyShields(selection: FamilyActivitySelection)
    func removeShields()
}

@MainActor
final class ScreenTimeService: ScreenTimeServiceProtocol {
    private let store = ManagedSettingsStore()

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    func applyShields(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        if selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = nil
        } else {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        if selection.webDomainTokens.isEmpty {
            store.shield.webDomains = nil
        } else {
            store.shield.webDomains = selection.webDomainTokens
        }
    }

    func removeShields() {
        store.clearAllSettings()
    }
}

#else

protocol ScreenTimeServiceProtocol: Sendable {
    func requestAuthorization() async throws
    func removeShields()
}

@MainActor
final class ScreenTimeService: ScreenTimeServiceProtocol {
    func requestAuthorization() async throws {}
    func removeShields() {}
}

#endif
