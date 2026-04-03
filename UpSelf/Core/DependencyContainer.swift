//
//  DependencyContainer.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//

import Foundation

protocol InjectionKey {
    associatedtype Value
    static var currentValue: Value { get set }
}

struct DependencyContainer {
    private static var current = DependencyContainer()
    
    static subscript<T>(_ key: T.Type) -> T.Value where T: InjectionKey {
        get { key.currentValue }
        set { key.currentValue = newValue }
    }
    
    static subscript<T>(_ keyPath: WritableKeyPath<DependencyContainer, T>) -> T {
        get { current[keyPath: keyPath] }
        set { current[keyPath: keyPath] = newValue }
    }
}

@propertyWrapper
struct Injected<T> {
    private let keyPath: WritableKeyPath<DependencyContainer, T>
    
    var wrappedValue: T {
        get { DependencyContainer[keyPath] }
        set { DependencyContainer[keyPath] = newValue }
    }
    
    init(_ keyPath: WritableKeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
}

extension DependencyContainer {
    var supabaseService: SupabaseServiceProtocol {
        get { DependencyContainer[SupabaseServiceKey.self] }
        set { DependencyContainer[SupabaseServiceKey.self] = newValue }
    }
}

private struct SupabaseServiceKey: InjectionKey {
    static var currentValue: SupabaseServiceProtocol = SupabaseService(
        url: AppConfig.supabaseURL,
        anonKey: AppConfig.supabaseAnonKey
    )
}

import SwiftData

extension DependencyContainer {
    var modelContainer: ModelContainer {
        get { DependencyContainer[ModelContainerKey.self] }
        set { DependencyContainer[ModelContainerKey.self] = newValue }
    }
}

private struct ModelContainerKey: InjectionKey {
    static var currentValue: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            CharacterStat.self,
            Quest.self,
            ActivityLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError(L10n.Errors.modelContainer(error))
        }
    }()
}

extension DependencyContainer {
    var dataSeedService: DataSeedServiceProtocol {
        get { DependencyContainer[DataSeedServiceKey.self] }
        set { DependencyContainer[DataSeedServiceKey.self] = newValue }
    }
}

private struct DataSeedServiceKey: InjectionKey {
    static var currentValue: DataSeedServiceProtocol = DataSeedService()
}

private struct GameClockKey: InjectionKey {
    static var currentValue: GameClock = GameClock()
}

extension DependencyContainer {
    var gameClock: GameClock {
        get { DependencyContainer[GameClockKey.self] }
        set { DependencyContainer[GameClockKey.self] = newValue }
    }
}
