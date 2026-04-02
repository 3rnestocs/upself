//
//  UpSelfApp.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import SwiftUI
import SwiftData

@main
struct UpSelfApp: App {
    let appCoordinator = AppCoordinator()
    // Obtenemos el contenedor desde nuestro DI central
    @Injected(\.modelContainer) var container

    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: appCoordinator)
                .ignoresSafeArea()
                // Esto habilita @Query y @Environment(\.modelContext) en TODAS las vistas
                .modelContainer(container)
        }
    }
}
