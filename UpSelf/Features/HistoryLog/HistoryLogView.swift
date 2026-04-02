//
//  HistoryLogView.swift
//  UpSelf
//
//  Terminal-style feed of XP / HP / system events (SwiftData via @Query).
//

import SwiftData
import SwiftUI

struct HistoryLogView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \ActivityLog.timestamp, order: .reverse) private var allLogs: [ActivityLog]

    private var profile: UserProfile? { profiles.first }

    private var logs: [ActivityLog] {
        guard let id = profile?.id else { return [] }
        return allLogs.filter { $0.user?.id == id }
    }

    var body: some View {
        Group {
            if logs.isEmpty {
                Text(L10n.HistoryLog.empty)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(AppTheme.Spacing.lg)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        ForEach(logs, id: \.id) { log in
                            logRow(log)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private func logRow(_ log: ActivityLog) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(AppTheme.Fonts.mono(.caption2))
                .foregroundStyle(AppTheme.Colors.secondaryLabel)
            Text(log.message)
                .font(AppTheme.Fonts.mono(.subheadline))
                .foregroundStyle(rowForeground(for: log.kind))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rowForeground(for kind: ActivityLogKind?) -> Color {
        switch kind {
        case .xpGain: AppTheme.Colors.accentXP
        case .hpLoss: AppTheme.Colors.alertHP
        case .system: AppTheme.Colors.secondaryLabel
        case .none: AppTheme.Colors.secondaryLabel
        }
    }
}
