//
//  GameClock.swift
//  UpSelf
//
//  Single source for gameplay “now” (daily quests, missed-daily evaluation). Simulation only — not for sync.
//

import Foundation
import Observation
import SwiftUI

private enum GameClockStorage {
    static let dayOffsetKey = "upself.gameClock.dayOffset"
}

/// Provides the effective current date for game rules. In DEBUG, `dayOffset` shifts calendar day from wall clock.
@Observable
final class GameClock {

    private let calendar: Calendar
    private let defaults: UserDefaults

    /// Calendar days added to wall-clock `Date()` (negative = pretend we are in the past).
    var dayOffset: Int {
        didSet {
            #if DEBUG
            defaults.set(dayOffset, forKey: GameClockStorage.dayOffsetKey)
            #endif
        }
    }

    init(calendar: Calendar = .current, defaults: UserDefaults = .standard) {
        self.calendar = calendar
        self.defaults = defaults
        #if DEBUG
        self.dayOffset = defaults.integer(forKey: GameClockStorage.dayOffsetKey)
        #else
        self.dayOffset = 0
        #endif
    }

    /// Effective “now” for dailies, `lastCompleted` stamps, and missed-daily evaluation.
    var now: Date {
        let wall = Date()
        #if DEBUG
        guard dayOffset != 0 else { return wall }
        return calendar.date(byAdding: .day, value: dayOffset, to: wall) ?? wall
        #else
        return wall
        #endif
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Preview label for a **draft** day offset (wall clock + offset → calendar date only).
    func formattedGameCalendarDayLabel(dayOffset draftOffset: Int) -> String {
        let wall = Date()
        let shifted = calendar.date(byAdding: .day, value: draftOffset, to: wall) ?? wall
        let start = calendar.startOfDay(for: shifted)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: start)
    }
}

// MARK: - Environment

private struct GameClockEnvironmentKey: EnvironmentKey {
    static var defaultValue: GameClock {
        DependencyContainer[\.gameClock]
    }
}

extension EnvironmentValues {
    var gameClock: GameClock {
        get { self[GameClockEnvironmentKey.self] }
        set { self[GameClockEnvironmentKey.self] = newValue }
    }
}
