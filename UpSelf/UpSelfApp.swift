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
    private let coordinator: AppCoordinator

    init() {
        let container = DependencyContainer[\.modelContainer]
        let context = ModelContext(container)
        DependencyContainer[\.dataSeedService].seedIfNeeded(context: context)
        coordinator = AppCoordinator(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator)
                .ignoresSafeArea()
                .modelContainer(DependencyContainer[\.modelContainer])
        }
    }
}

/// Wires scene activation to `MissedDailyPenaltyService` (UIKit navigation stays in `AppCoordinator`).
private struct AppRootView: View {
    let coordinator: AppCoordinator

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        CoordinatorView(coordinator: coordinator)
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                // Defer past this run loop so `UIHostingController` / tab roots can attach to the key window
                // before any `UIAlertController` presentation (avoids “first alert is slow”, works smooth after).
                DispatchQueue.main.async {
                    let context = ModelContext(DependencyContainer[\.modelContainer])
                    do {
                        let lost = try MissedDailyPenaltyService.evaluateIfNeeded(
                            context: context,
                            clock: DependencyContainer[\.gameClock]
                        )
                        if lost > 0 {
                            coordinator.presentMissedDailyHPLossAlert(totalHPLost: lost)
                        }
                    } catch {
                        assertionFailure("MissedDailyPenaltyService: \(error)")
                    }
                }
            }
    }
}
