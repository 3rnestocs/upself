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
    }

    enum Stats {
        static let unknown = LocalizedStringResource("stat.unknown")

        static let logistics = LocalizedStringResource("stat.logistics")
        static let mastery = LocalizedStringResource("stat.mastery")
        static let charisma = LocalizedStringResource("stat.charisma")
        static let willpower = LocalizedStringResource("stat.willpower")
        static let vitality = LocalizedStringResource("stat.vitality")
        static let economy = LocalizedStringResource("stat.economy")

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

    /// Default quest titles seeded on first launch (`DataSeedService`).
    enum SeedQuests {
        static let vitalityWater = LocalizedStringResource("seed.quest.vitality.water")
        static let vitalityTrain45 = LocalizedStringResource("seed.quest.vitality.train45")
        static let vitalityRun5k = LocalizedStringResource("seed.quest.vitality.run5k")
        static let logisticsBed = LocalizedStringResource("seed.quest.logistics.bed")
        static let logisticsWeekPlan = LocalizedStringResource("seed.quest.logistics.week_plan")
        static let logisticsDeepClean = LocalizedStringResource("seed.quest.logistics.deep_clean")
        static let masteryRead10 = LocalizedStringResource("seed.quest.mastery.read10")
        static let masteryStudy2h = LocalizedStringResource("seed.quest.mastery.study2h")
        static let vitalityBrush3x = LocalizedStringResource("seed.quest.vitality.brush3x")
        static let vitalityMealOnTime = LocalizedStringResource("seed.quest.vitality.meal_on_time")
        static let masteryUniversityStudy = LocalizedStringResource("seed.quest.mastery.university_study")
        static let economyWork2hUninterrupted = LocalizedStringResource("seed.quest.economy.work2h_uninterrupted")
        static let masteryUpSelf1h = LocalizedStringResource("seed.quest.mastery.upself1h")
        static let charismaActivityClaudia = LocalizedStringResource("seed.quest.charisma.activity_claudia")
        static let willpowerGamingSchedule = LocalizedStringResource("seed.quest.willpower.gaming_schedule")
        static let willpowerSeriesSchedule = LocalizedStringResource("seed.quest.willpower.series_schedule")
        static let masteryEnglishPractice = LocalizedStringResource("seed.quest.mastery.english_practice")
        static let logisticsMealPrep = LocalizedStringResource("seed.quest.logistics.meal_prep")
        static let willpowerColdShower = LocalizedStringResource("seed.quest.willpower.cold_shower")
        static let willpowerMeditate10 = LocalizedStringResource("seed.quest.willpower.meditate10")
        static let willpowerNoSugar = LocalizedStringResource("seed.quest.willpower.no_sugar")
        static let economyTrackExpenses = LocalizedStringResource("seed.quest.economy.track_expenses")
        static let economyNoDelivery = LocalizedStringResource("seed.quest.economy.no_delivery")
        static let charismaCallFriend = LocalizedStringResource("seed.quest.charisma.call_friend")
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

        static func missedDailyMessage(questTitle: String, dayLabel: String, hp: Int) -> String {
            String(
                format: String(localized: "activity_log.hp.missed_daily"),
                locale: .current,
                arguments: [hp as CVarArg, questTitle as CVarArg, dayLabel as CVarArg]
            )
        }
    }
}
