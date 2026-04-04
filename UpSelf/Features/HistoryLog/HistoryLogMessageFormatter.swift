//
//  HistoryLogMessageFormatter.swift
//  UpSelf
//
//  Parses activity log copy for presentation (e.g. XP gain head + stat line).
//

import SwiftUI

enum HistoryLogMessageFormatter {

    struct XPGainLines: Equatable {
        let xpOrQuestLine: String
        let statLine: String
    }

    /// XP logs store `head\nstat` (`L10n.ActivityLogCopy` + `ActivityLogService`).
    static func splitXPGainMessage(_ message: String) -> XPGainLines? {
        let parts = message.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let head = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let stat = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !head.isEmpty, !stat.isEmpty else { return nil }
        return XPGainLines(xpOrQuestLine: head, statLine: stat)
    }

    static func rowForeground(for kind: ActivityLogKind?) -> Color {
        switch kind {
        case .xpGain: AppTheme.Colors.accentXP
        case .hpLoss: AppTheme.Colors.alertHP
        case .system: AppTheme.Colors.secondaryLabel
        case .none: AppTheme.Colors.secondaryLabel
        }
    }
}
