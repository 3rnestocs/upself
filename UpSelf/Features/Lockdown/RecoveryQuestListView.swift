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

private struct RecoveryQuestPendingCompletion: Identifiable {
    let id: UUID
    let title: String
}

struct RecoveryQuestListView: View {
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @Query(sort: \Quest.title) private var allQuests: [Quest]

    @Bindable private var gameClock = DependencyContainer[\.gameClock]

    private let viewModel: QuestLogViewModel

    @State private var showLockdownBlockedAlert = false
    @State private var pendingCompletion: RecoveryQuestPendingCompletion?

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
        .alert(String(localized: L10n.Lockdown.recoveryCompleteConfirmTitle), isPresented: Binding(
            get: { pendingCompletion != nil },
            set: { if !$0 { pendingCompletion = nil } }
        )) {
            Button(String(localized: L10n.Common.cancel), role: .cancel) {
                pendingCompletion = nil
            }
            Button(String(localized: L10n.Lockdown.recoveryCompleteConfirmAction)) {
                confirmPendingCompletion()
            }
        } message: {
            if let pending = pendingCompletion {
                Text(L10n.Lockdown.recoveryCompleteConfirmMessage(questTitle: pending.title))
            }
        }
        .alert(String(localized: L10n.Lockdown.cannotCompleteEasyRegularTitle), isPresented: $showLockdownBlockedAlert) {
            Button(String(localized: L10n.Common.ok), role: .cancel) {
                viewModel.clearLockdownNotice()
            }
        } message: {
            Text(verbatim: viewModel.lockdownBlockedNotice ?? "")
        }
        .onChange(of: viewModel.lockdownBlockedNotice) { _, new in
            showLockdownBlockedAlert = (new != nil)
        }
    }

    private func requestComplete(_ quest: Quest) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        pendingCompletion = RecoveryQuestPendingCompletion(
            id: quest.id,
            title: quest.title
        )
    }

    private func confirmPendingCompletion() {
        guard let pending = pendingCompletion else { return }
        let questID = pending.id
        pendingCompletion = nil
        DispatchQueue.main.async {
            guard let quest = allQuests.first(where: { $0.id == questID }) else { return }
            viewModel.completePersistedQuest(quest)
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
