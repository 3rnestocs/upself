//
//  ActivityLogKind.swift
//  UpSelf
//
//  Persisted on `ActivityLog` as a stable `rawValue`.
//

import Foundation

enum ActivityLogKind: String, Codable, CaseIterable, Sendable {
    case xpGain
    case hpLoss
    case system
}
