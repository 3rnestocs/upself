//
//  AppCoordinator.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import UIKit
import SwiftUI

class AppCoordinator {
    // Este es el motor de navegación de UIKit
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Aquí instanciamos nuestra primera vista (Dashboard)
        // Por ahora, pondremos un controlador en blanco con fondo rojo para probar
        let initialVC = UIHostingController(rootView: Text("¡El Coordinator Funciona!").font(.largeTitle))
        initialVC.view.backgroundColor = .systemRed
        
        navigationController.pushViewController(initialVC, animated: false)
    }
}

import SwiftUI

struct CoordinatorView: UIViewControllerRepresentable {
    let coordinator: AppCoordinator
    
    // SwiftUI llama a este método una vez para crear el controlador de UIKit
    func makeUIViewController(context: Context) -> UINavigationController {
        coordinator.start() // Arrancamos el flujo
        return coordinator.navigationController // Le entregamos el control a SwiftUI
    }
    
    // Este método es obligatorio, pero lo dejamos vacío porque nuestro Coordinator gestiona las actualizaciones
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
