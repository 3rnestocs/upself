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
    nonisolated(unsafe) private static var current = DependencyContainer()
    
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
    static var currentValue: SupabaseServiceProtocol = {
        guard let url = AppConfig.supabaseURL else {
            assertionFailure("Supabase URL not configured — copy Secrets.template.xcconfig → Secrets.xcconfig and assign it in Xcode project settings.")
            return NoOpSupabaseService()
        }
        return SupabaseService(url: url, anonKey: AppConfig.supabaseAnonKey)
    }()
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

private struct LocalAppResetServiceKey: InjectionKey {
    static var currentValue: LocalAppResetServiceProtocol = LocalAppResetService()
}

extension DependencyContainer {
    var localAppResetService: LocalAppResetServiceProtocol {
        get { DependencyContainer[LocalAppResetServiceKey.self] }
        set { DependencyContainer[LocalAppResetServiceKey.self] = newValue }
    }
}

private struct ActivityLogServiceKey: InjectionKey {
    static var currentValue: ActivityLogServiceProtocol = ActivityLogService(
        gameClock: DependencyContainer[\.gameClock]
    )
}

extension DependencyContainer {
    var activityLogService: ActivityLogServiceProtocol {
        get { DependencyContainer[ActivityLogServiceKey.self] }
        set { DependencyContainer[ActivityLogServiceKey.self] = newValue }
    }
}

private struct LockdownEvaluationServiceKey: InjectionKey {
    static var currentValue: LockdownEvaluationServiceProtocol = LockdownEvaluationService()
}

extension DependencyContainer {
    var lockdownEvaluationService: LockdownEvaluationServiceProtocol {
        get { DependencyContainer[LockdownEvaluationServiceKey.self] }
        set { DependencyContainer[LockdownEvaluationServiceKey.self] = newValue }
    }
}

private struct QuestCompletionServiceKey: InjectionKey {
    static var currentValue: QuestCompletionServiceProtocol = QuestCompletionService(
        gameClock: DependencyContainer[\.gameClock]
    )
}

extension DependencyContainer {
    var questCompletionService: QuestCompletionServiceProtocol {
        get { DependencyContainer[QuestCompletionServiceKey.self] }
        set { DependencyContainer[QuestCompletionServiceKey.self] = newValue }
    }
}
