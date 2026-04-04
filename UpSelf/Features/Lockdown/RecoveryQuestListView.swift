//
//  RecoveryQuestListView.swift
//  UpSelf
//
//  Pushed screen: hard & epic quests only (lockdown recovery). Same row UX as Quest Log + confirm alert.
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RecoveryQuestListView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Environment(\.gameClock) private var gameClock

    private let viewModel: QuestLogViewModel

    init(viewModel: QuestLogViewModel) {
        self.viewModel = viewModel
    }

    private var profile: UserProfile? { profiles.first }

    private var recoveryEpicQuests: [Quest] {
        recoveryQuestsFiltered(tier: .epic)
    }

    private var recoveryHardQuests: [Quest] {
        recoveryQuestsFiltered(tier: .hard)
    }

    private var hasAnyRecoveryQuest: Bool {
        !recoveryEpicQuests.isEmpty || !recoveryHardQuests.isEmpty
    }

    private func recoveryQuestsFiltered(tier: QuestRewardTier) -> [Quest] {
        guard let id = profile?.id else { return [] }
        let ref = gameClock.now
        let episodeStart = profile?.lockdownEpisodeStart
        return allQuests.filter { quest in
            guard quest.user?.id == id else { return false }
            return quest.rewardTier == tier
        }
        .sorted { a, b in
            let ad = a.recoveryListDisplayCompleted(referenceDate: ref, lockdownEpisodeStart: episodeStart)
            let bd = b.recoveryListDisplayCompleted(referenceDate: ref, lockdownEpisodeStart: episodeStart)
            if ad != bd { return !ad && bd }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if !hasAnyRecoveryQuest {
                Text(L10n.Lockdown.recoveryEmpty)
                    .font(AppTheme.Fonts.ui(.subheadline))
                    .foregroundStyle(AppTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                List {
                    if !recoveryEpicQuests.isEmpty {
                        Section {
                            ForEach(recoveryEpicQuests, id: \.id) { quest in
                                recoveryQuestRow(quest)
                                    .listRowInsets(EdgeInsets(
                                        top: AppTheme.Spacing.xs,
                                        leading: 0,
                                        bottom: AppTheme.Spacing.xs,
                                        trailing: 0
                                    ))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(L10n.Lockdown.recoverySectionEpicHeader(
                                done: profile?.lockdownEpicCompletions ?? 0,
                                needed: profile?.lockdownMinEpicQuestsToClear ?? 0
                            ))
                            .font(AppTheme.Fonts.ui(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.accentXP)
                            .textCase(nil)
                        }
                    }
                    if !recoveryHardQuests.isEmpty {
                        Section {
                            ForEach(recoveryHardQuests, id: \.id) { quest in
                                recoveryQuestRow(quest)
                                    .listRowInsets(EdgeInsets(
                                        top: AppTheme.Spacing.xs,
                                        leading: 0,
                                        bottom: AppTheme.Spacing.xs,
                                        trailing: 0
                                    ))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(L10n.Lockdown.recoverySectionHardHeader(
                                done: profile?.lockdownHardCompletions ?? 0,
                                needed: profile?.lockdownMinHardQuestsToClear ?? 0
                            ))
                            .font(AppTheme.Fonts.ui(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.accentXP)
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.background)
    }

    private func requestComplete(_ quest: Quest) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        let questID = quest.id
        viewModel.presentRecoveryQuestCompleteConfirm(questTitle: quest.title) {
            DispatchQueue.main.async {
                guard let q = allQuests.first(where: { $0.id == questID }) else { return }
                viewModel.completePersistedQuest(q)
            }
        }
    }

    @ViewBuilder
    private func recoveryQuestRow(_ quest: Quest) -> some View {
        let ref = gameClock.now
        let episodeStart = profile?.lockdownEpisodeStart
        let done = quest.recoveryListDisplayCompleted(referenceDate: ref, lockdownEpisodeStart: episodeStart)
        let canComplete = quest.recoveryListCanComplete(referenceDate: ref, lockdownEpisodeStart: episodeStart)
        let tierBlockedInLockdown = isTierBlockedInLockdown(quest)
        let content = QuestLogRowCard(
            quest: quest,
            done: done,
            canComplete: canComplete,
            tierBlockedInLockdown: tierBlockedInLockdown
        )

        if canComplete, !tierBlockedInLockdown {
            content
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        requestComplete(quest)
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

    private func isTierBlockedInLockdown(_ quest: Quest) -> Bool {
        guard let profile, profile.isInLockdown, let tier = quest.rewardTier else { return false }
        return !LockdownPolicy.allows(.completeQuest(tier: tier), isInLockdown: true)
    }
}
