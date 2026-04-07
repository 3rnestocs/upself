//
//  L10n.swift
//  UpSelf
//
//  Strongly-typed access to `Localizable.xcstrings`. Views and ViewModels must use
//  `L10n` only — never `String(localized: "…")` or ad hoc string keys in UI code.
//

import Foundation

/// Central namespace for localized copy. Keys mirror `Localizable.xcstrings`.
enum L10n {

    enum App {
        static let title = LocalizedStringResource("app.title")
    }

    enum Common {
        static let placeholder = LocalizedStringResource("common.placeholder")
        static let ok = LocalizedStringResource("common.ok")
        static let done = LocalizedStringResource("common.done")
        static let cancel = LocalizedStringResource("common.cancel")
    }

    enum Lockdown {
        static let exitSuccessTitle = LocalizedStringResource("lockdown.exit_success.title")
        static let exitSuccessMessage = LocalizedStringResource("lockdown.exit_success.message")
        static let dailyBriefBlockedFootnote = LocalizedStringResource("lockdown.daily_brief.blocked_footnote")
        static let recoveryTitle = LocalizedStringResource("lockdown.recovery.title")
        static let recoveryViewQuestsButton = LocalizedStringResource("lockdown.recovery.view_quests")
        static let recoverySheetTitle = LocalizedStringResource("lockdown.recovery.sheet_title")
        static let recoveryEmpty = LocalizedStringResource("lockdown.recovery.empty")

        static func recoverySectionEpicHeader(done: Int, needed: Int) -> String {
            String(
                format: String(localized: "lockdown.recovery.section.epic_progress %lld %lld"),
                locale: .current,
                arguments: [done, needed] as [CVarArg]
            )
        }

        static func recoverySectionHardHeader(done: Int, needed: Int) -> String {
            String(
                format: String(localized: "lockdown.recovery.section.hard_progress %lld %lld"),
                locale: .current,
                arguments: [done, needed] as [CVarArg]
            )
        }
        static let recoveryCompleteConfirmTitle = LocalizedStringResource("lockdown.recovery.complete_confirm.title")
        static let recoveryCompleteConfirmAction = LocalizedStringResource("lockdown.recovery.complete_confirm.confirm")

        static func recoveryCompleteConfirmMessage(questTitle: String) -> String {
            String(
                format: String(localized: "lockdown.recovery.complete_confirm.body %@"),
                locale: .current,
                arguments: [questTitle] as [CVarArg]
            )
        }

        static let cannotCompleteEasyRegularTitle = LocalizedStringResource("lockdown.quest.blocked_title")
        static let cannotCompleteEasyRegularBody = LocalizedStringResource("lockdown.quest.blocked_body")
        static let questRowLockedLabel = LocalizedStringResource("lockdown.quest.row_locked")
        static let createQuestBlockedTitle = LocalizedStringResource("lockdown.create_quest.blocked_title")
        static let createQuestBlockedBody = LocalizedStringResource("lockdown.create_quest.blocked_body")
        static let recoveryProgressLine = LocalizedStringResource("lockdown.recovery.progress_line")
        static let recoveryInfoAlertTitle = LocalizedStringResource("lockdown.recovery.info_alert.title")
        static let recoveryInfoButtonAccessibility = LocalizedStringResource("lockdown.recovery.info_button.accessibility")

        static func recoveryInfoAlertMessage(minHard: Int, minEpic: Int) -> String {
            func hardRequirementPhrase(_ count: Int) -> String {
                if count == 1 {
                    return String(
                        format: String(localized: "lockdown.recovery.info_alert.hard.singular %lld"),
                        locale: .current,
                        arguments: [count] as [CVarArg]
                    )
                }
                return String(
                    format: String(localized: "lockdown.recovery.info_alert.hard.plural %lld"),
                    locale: .current,
                    arguments: [count] as [CVarArg]
                )
            }
            func epicRequirementPhrase(_ count: Int) -> String {
                if count == 1 {
                    return String(
                        format: String(localized: "lockdown.recovery.info_alert.epic.singular %lld"),
                        locale: .current,
                        arguments: [count] as [CVarArg]
                    )
                }
                return String(
                    format: String(localized: "lockdown.recovery.info_alert.epic.plural %lld"),
                    locale: .current,
                    arguments: [count] as [CVarArg]
                )
            }

            let hardActive = minHard > 0
            let epicActive = minEpic > 0
            if hardActive && epicActive {
                return String(
                    format: String(localized: "lockdown.recovery.info_alert.body_both"),
                    locale: .current,
                    arguments: [hardRequirementPhrase(minHard), epicRequirementPhrase(minEpic)] as [CVarArg]
                )
            }
            if hardActive {
                return String(
                    format: String(localized: "lockdown.recovery.info_alert.body_hard_only %@"),
                    locale: .current,
                    arguments: [hardRequirementPhrase(minHard)] as [CVarArg]
                )
            }
            if epicActive {
                return String(
                    format: String(localized: "lockdown.recovery.info_alert.body_epic_only %@"),
                    locale: .current,
                    arguments: [epicRequirementPhrase(minEpic)] as [CVarArg]
                )
            }
            return String(localized: "lockdown.recovery.info_alert.body_fallback")
        }
    }

    enum HUD {
        static let hpLabel = LocalizedStringResource("hud.hp.label")
        static let attributesTitle = LocalizedStringResource("hud.attributes.title")
        static let questsSectionTitle = LocalizedStringResource("hud.quests.section_title")
        static let questsSectionDaily = LocalizedStringResource("hud.quests.section_daily")
        static let questsSectionNonDaily = LocalizedStringResource("hud.quests.section_non_daily")
        static let questDailyBadge = LocalizedStringResource("hud.quest.daily_badge")
        static let questCompleteAction = LocalizedStringResource("hud.quest.complete_action")
        static let questDoneToday = LocalizedStringResource("hud.quest.done_today")
        static let questDoneOnce = LocalizedStringResource("hud.quest.done_once")
        static let addQuest = LocalizedStringResource("hud.add_quest")
        static let openActivityLog = LocalizedStringResource("hud.open_activity_log")
        static let openQuestLog = LocalizedStringResource("hud.open_quest_log")
        static let dailyBriefingTitle = LocalizedStringResource("hud.daily_briefing.title")
        static let statsInfoTitle = LocalizedStringResource("hud.stats_info.title")
        static let statsInfoDone = LocalizedStringResource("hud.stats_info.done")
        static let statsInfoButtonAccessibility = LocalizedStringResource("hud.stats_info.button_accessibility")
        static let hpLossAlertTitle = LocalizedStringResource("hud.hp_loss_alert.title")
        static let hpLossAlertAccept = LocalizedStringResource("hud.hp_loss_alert.accept")

        static func hpLossAlertMessage(totalLost: Int) -> String {
            String(
                format: String(localized: "hud.hp_loss_alert.message %lld"),
                locale: .current,
                arguments: [totalLost as CVarArg]
            )
        }

        static func hpPair(current: Int, max: Int) -> String {
            String(localized: "hp.pair \(current) \(max)")
        }

        static func levelFormat(level: Int) -> String {
            String(localized: "hud.level.format \(level)")
        }

        static func xpFormat(xp: Int) -> String {
            String(localized: "hud.xp.format \(xp)")
        }

        static func dailyBriefingSummary(completed: Int, total: Int) -> String {
            String(
                format: String(localized: "hud.daily_briefing.summary %lld %lld"),
                locale: .current,
                arguments: [completed, total] as [CVarArg]
            )
        }
    }

    enum QuestLog {
        static let title = LocalizedStringResource("quest_log.title")
        static let filterDaily = LocalizedStringResource("quest_log.filter.daily")
        static let filterOneOff = LocalizedStringResource("quest_log.filter.one_off")
        static let filterAccessibility = LocalizedStringResource("quest_log.filter.accessibility")
        static let empty = LocalizedStringResource("quest_log.empty")
        static let dashboardOneOffTeaser = LocalizedStringResource("quest_log.dashboard.one_off_teaser")
        static let instructionsTitle = LocalizedStringResource("quest_log.instructions.title")
        static let instructionsBody = LocalizedStringResource("quest_log.instructions.body")
        static let instructionsButtonAccessibility = LocalizedStringResource("quest_log.instructions.button_accessibility")
    }

    enum Settings {
        static let title = LocalizedStringResource("settings.title")
        static let tabHome = LocalizedStringResource("settings.tab.home")
        static let tabSettings = LocalizedStringResource("settings.tab.settings")
        static let aboutSection = LocalizedStringResource("settings.about.section")
        static let appNameLabel = LocalizedStringResource("settings.about.app_name")
        static let versionLabel = LocalizedStringResource("settings.about.version")
        static let developerSection = LocalizedStringResource("settings.developer.section")
        static let gameClockLabel = LocalizedStringResource("settings.developer.game_clock")
        static let gameClockFooter = LocalizedStringResource("settings.developer.footer")
        static let resetWatermark = LocalizedStringResource("settings.developer.reset_watermark")
        static let applyGameDay = LocalizedStringResource("settings.developer.apply")
        static let useRealToday = LocalizedStringResource("settings.developer.use_real_today")
        static let effectiveGameDay = LocalizedStringResource("settings.developer.effective_day")
        static let draftPending = LocalizedStringResource("settings.developer.draft_pending")
        static let watermarkResetDone = LocalizedStringResource("settings.developer.watermark_done")
        static let watermarkResetFailed = LocalizedStringResource("settings.developer.watermark_failed")

        static func gameClockOffsetDescription(_ offset: Int) -> String {
            String(
                format: String(localized: "settings.developer.offset %lld"),
                locale: .current,
                arguments: [offset as CVarArg]
            )
        }

        static let lockdownSection = LocalizedStringResource("settings.lockdown.section")
        static let lockdownMinEpicLabel = LocalizedStringResource("settings.lockdown.min_epic")
        static let lockdownMinHardLabel = LocalizedStringResource("settings.lockdown.min_hard")
        static let lockdownFooter = LocalizedStringResource("settings.lockdown.footer")
        static let lockdownSaveFailed = LocalizedStringResource("settings.lockdown.save_failed")

        static let dataSection = LocalizedStringResource("settings.data.section")
        static let dataResetFooter = LocalizedStringResource("settings.data.reset_footer")
        static let dataResetButton = LocalizedStringResource("settings.data.reset_button")
        static let dataResetAlertTitle = LocalizedStringResource("settings.data.reset_alert.title")
        static let dataResetAlertMessage = LocalizedStringResource("settings.data.reset_alert.message")
        static let dataResetConfirm = LocalizedStringResource("settings.data.reset_confirm")
        static let dataResetDone = LocalizedStringResource("settings.data.reset_done")
        static let dataResetFailed = LocalizedStringResource("settings.data.reset_failed")
    }

    enum Stats {
        static let unknown = LocalizedStringResource("stat.unknown")

        static let logistics = LocalizedStringResource("stat.logistics")
        static let mastery = LocalizedStringResource("stat.mastery")
        static let charisma = LocalizedStringResource("stat.charisma")
        static let willpower = LocalizedStringResource("stat.willpower")
        static let vitality = LocalizedStringResource("stat.vitality")
        static let economy = LocalizedStringResource("stat.economy")

        static let logisticsInfo = LocalizedStringResource("stat.logistics.info")
        static let masteryInfo = LocalizedStringResource("stat.mastery.info")
        static let charismaInfo = LocalizedStringResource("stat.charisma.info")
        static let willpowerInfo = LocalizedStringResource("stat.willpower.info")
        static let vitalityInfo = LocalizedStringResource("stat.vitality.info")
        static let economyInfo = LocalizedStringResource("stat.economy.info")

        static func title(for attribute: CharacterAttribute) -> LocalizedStringResource {
            switch attribute {
            case .logistics: logistics
            case .mastery: mastery
            case .charisma: charisma
            case .willpower: willpower
            case .vitality: vitality
            case .economy: economy
            }
        }

        static func description(for attribute: CharacterAttribute) -> LocalizedStringResource {
            switch attribute {
            case .logistics: logisticsInfo
            case .mastery: masteryInfo
            case .charisma: charismaInfo
            case .willpower: willpowerInfo
            case .vitality: vitalityInfo
            case .economy: economyInfo
            }
        }
    }

    enum Accessibility {
        static var xpProgress: String {
            String(localized: "accessibility.xp_progress")
        }

        static func xpPercent(_ percent: Int) -> String {
            String(localized: "accessibility.xp.percent \(percent)")
        }

        static func completeQuestButton(_ questTitle: String) -> String {
            String(
                format: String(localized: "accessibility.quest.complete_button %@"),
                locale: .current,
                arguments: [questTitle as CVarArg]
            )
        }

        // HP bar
        static var hpLabel: String {
            String(localized: "accessibility.hp.label")
        }

        static func hpValue(current: Int, max: Int) -> String {
            String(
                format: String(localized: "accessibility.hp.value %lld %lld"),
                locale: .current,
                arguments: [current, max] as [CVarArg]
            )
        }

        // Quest rows
        static var questSwipeHint: String {
            String(localized: "accessibility.quest.swipe_to_complete")
        }

        static func questRowLabel(title: String, xp: Int) -> String {
            String(
                format: String(localized: "accessibility.quest.row_label %@ %lld"),
                locale: .current,
                arguments: [title as CVarArg, xp as CVarArg]
            )
        }

        static var questDone: String {
            String(localized: "accessibility.quest.done")
        }

        static var questTierBlocked: String {
            String(localized: "accessibility.quest.tier_blocked")
        }
    }

    enum Errors {
        static func modelContainer(_ error: Error) -> String {
            String(format: String(localized: "error.model_container"), String(describing: error))
        }
    }

    enum CreateQuest {
        static let navTitle = LocalizedStringResource("create_quest.nav_title")
        static let cancel = LocalizedStringResource("create_quest.cancel")
        static let save = LocalizedStringResource("create_quest.save")
        static let fieldTitle = LocalizedStringResource("create_quest.field_title")
        static let fieldTier = LocalizedStringResource("create_quest.field_tier")
        static let fieldAttribute = LocalizedStringResource("create_quest.field_attribute")
        static let fieldDaily = LocalizedStringResource("create_quest.field_daily")
        static let validationTitleEmpty = LocalizedStringResource("create_quest.validation.title_empty")
        static let validationNoProfile = LocalizedStringResource("create_quest.validation.no_profile")
        static let validationSaveFailed = LocalizedStringResource("create_quest.validation.save_failed")

        static func tierName(_ tier: QuestRewardTier) -> LocalizedStringResource {
            switch tier {
            case .easy: LocalizedStringResource("create_quest.tier.easy")
            case .regular: LocalizedStringResource("create_quest.tier.regular")
            case .hard: LocalizedStringResource("create_quest.tier.hard")
            case .epic: LocalizedStringResource("create_quest.tier.epic")
            }
        }
    }

    enum HistoryLog {
        static let title = LocalizedStringResource("history_log.title")
        static let empty = LocalizedStringResource("history_log.empty")
    }

    enum ActivityLogCopy {
        /// First line: XP only; second line (joined with `\n`): stat — for `HistoryLogView` layout.
        static func xpGainMessage(xp: Int, attribute: CharacterAttribute) -> String {
            let head = String(
                format: String(localized: "activity_log.xp.head"),
                locale: .current,
                arguments: [xp as CVarArg]
            )
            let statName = String(localized: L10n.Stats.title(for: attribute))
            return head + "\n" + statName
        }

        /// First line: XP + quest title; second line: stat — for `HistoryLogView` layout.
        static func xpGainQuestMessage(xp: Int, questTitle: String, attribute: CharacterAttribute) -> String {
            let head = String(
                format: String(localized: "activity_log.xp.quest_head"),
                locale: .current,
                arguments: [xp as CVarArg, questTitle as CVarArg]
            )
            let statName = String(localized: L10n.Stats.title(for: attribute))
            return head + "\n" + statName
        }

        /// HP loss when the full daily set was not completed on a calendar day (one line for activity log).
        static func missedDailySetMessage(dayLabel: String, hp: Int) -> String {
            String(
                format: String(localized: "activity_log.hp.missed_daily_set"),
                locale: .current,
                arguments: [hp as CVarArg, dayLabel as CVarArg]
            )
        }
    }
}
