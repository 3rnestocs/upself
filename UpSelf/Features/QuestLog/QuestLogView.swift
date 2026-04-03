//
//  QuestLogView.swift
//  UpSelf
//
//  Action center: filter dailies vs one-offs, swipe to complete.
//

import SwiftData
import SwiftUI

private enum QuestLogFilter: Hashable {
    case daily
    case oneOff
}

struct QuestLogView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Bindable private var gameClock = DependencyContainer[\.gameClock]

    private let viewModel: QuestLogViewModel

    @State private var filter: QuestLogFilter = .daily
    @State private var showInstructions = false

    init(viewModel: QuestLogViewModel) {
        self.viewModel = viewModel
    }

    private var profile: UserProfile? { profiles.first }

    private var filteredQuests: [Quest] {
        guard let id = profile?.id else { return [] }
        let subset = allQuests.filter { quest in
            guard quest.user?.id == id else { return false }
            switch filter {
            case .daily: return quest.isDaily
            case .oneOff: return !quest.isDaily
            }
        }
        let ref = gameClock.now
        return subset.sorted { a, b in
            let ad = a.displayAsCompleted(referenceDate: ref)
            let bd = b.displayAsCompleted(referenceDate: ref)
            if ad != bd { return !ad && bd }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Picker("", selection: $filter) {
                Text(L10n.QuestLog.filterDaily).tag(QuestLogFilter.daily)
                Text(L10n.QuestLog.filterOneOff).tag(QuestLogFilter.oneOff)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.QuestLog.filterAccessibility)

            if filteredQuests.isEmpty {
                Text(L10n.QuestLog.empty)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                List {
                    ForEach(filteredQuests, id: \.id) { quest in
                        questRow(quest)
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.xs,
                                leading: 0,
                                bottom: AppTheme.Spacing.xs,
                                trailing: 0
                            ))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInstructions = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: L10n.QuestLog.instructionsButtonAccessibility))
            }
        }
        .alert(String(localized: L10n.QuestLog.instructionsTitle), isPresented: $showInstructions) {
            Button(String(localized: L10n.Common.ok), role: .cancel) {}
        } message: {
            Text(L10n.QuestLog.instructionsBody)
        }
    }

    @ViewBuilder
    private func questRow(_ quest: Quest) -> some View {
        let ref = gameClock.now
        let done = quest.displayAsCompleted(referenceDate: ref)
        let canComplete = quest.canComplete(referenceDate: ref)
        let content = questRowContent(quest, done: done, canComplete: canComplete)

        if canComplete {
            content
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        let q = quest
                        // Defer mutation until List/UIKit finishes swipe layout (avoids UICollectionView inconsistency).
                        DispatchQueue.main.async {
                            viewModel.completePersistedQuest(q)
                        }
                    } label: {
                        Label {
                            Text(L10n.HUD.questCompleteAction)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .tint(AppTheme.Colors.amber)
                }
        } else {
            content
        }
    }

    private func questRowContent(_ quest: Quest, done: Bool, canComplete: Bool) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(quest.title)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .lineLimit(3)
                if let kind = quest.statKind {
                    Text(L10n.Stats.title(for: kind))
                        .font(AppTheme.Fonts.mono(.caption))
                        .foregroundStyle(AppTheme.Colors.secondaryLabel)
                }
            }
            Spacer(minLength: AppTheme.Spacing.sm)

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                if let tier = quest.rewardTier {
                    Text(L10n.HUD.xpFormat(xp: tier.xp))
                        .font(AppTheme.Fonts.mono(.subheadline))
                        .foregroundStyle(AppTheme.Colors.accentXP)
                }

                if !canComplete, done {
                    Text(quest.isDaily ? L10n.HUD.questDoneToday : L10n.HUD.questDoneOnce)
                        .font(AppTheme.Fonts.mono(.caption2))
                        .foregroundStyle(AppTheme.Colors.accentXP.opacity(0.9))
                        .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.Colors.card)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(AppTheme.Colors.cardStroke, lineWidth: AppTheme.Stroke.cardLine)
        )
        .opacity(done ? 0.6 : 1)
    }
}
