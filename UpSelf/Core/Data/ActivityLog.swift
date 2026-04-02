//
//  ActivityLog.swift
//  UpSelf
//
//  Retro-style event feed (XP, HP, system messages).
//

import Foundation
import SwiftData

@Model
final class ActivityLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var message: String
    var kindRawValue: String

    var user: UserProfile?

    var kind: ActivityLogKind? {
        ActivityLogKind(rawValue: kindRawValue)
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        message: String,
        kind: ActivityLogKind,
        user: UserProfile? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.kindRawValue = kind.rawValue
        self.user = user
    }
}
