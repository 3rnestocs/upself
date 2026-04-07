//
//  UpSelfApp.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import SwiftData
import SwiftUI

@main
struct UpSelfApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let navigator = AppNavigator()

    init() {
        let container = DependencyContainer[\.modelContainer]
        let context = ModelContext(container)
        DependencyContainer[\.dataSeedService].seedIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .ignoresSafeArea()
                .environment(navigator)
                .environment(\.gameClock, DependencyContainer[\.gameClock])
                .modelContainer(DependencyContainer[\.modelContainer])
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { @MainActor in
                evaluateMissedDailyPenalty()
            }
        }
    }

    @MainActor
    private func evaluateMissedDailyPenalty() {
        let context = DependencyContainer[\.modelContainer].mainContext
        do {
            let lost = try MissedDailyPenaltyService.evaluateIfNeeded(
                context: context,
                clock: DependencyContainer[\.gameClock]
            )
            if lost > 0 {
                navigator.enqueueAlert(
                    .missedDailyHPLoss(totalHPLost: lost) { [weak navigator] in
                        navigator?.switchToHomeAndPopToRoot()
                    }
                )
            }
        } catch {
            assertionFailure("MissedDailyPenaltyService: \(error)")
        }
    }
}
