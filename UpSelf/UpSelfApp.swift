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
            CoordinatorView(coordinator: coordinator)
                .ignoresSafeArea()
                .modelContainer(DependencyContainer[\.modelContainer])
        }
    }
}
