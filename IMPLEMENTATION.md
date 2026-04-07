# UpSelf — Implementation Roadmap

This document tracks the current state of features and the suggested roadmap for future development.

---

## Shipped Features

| Module | Area | Description |
|---|---|---|
| **Dashboard** | Core UI | Character stats display, HP bar, active quests overview, XP progress to next level |
| **Quest Log** | Core UI | View all quests; filter between completed and ongoing; mark quests as done |
| **Create Quest** | Core UI | Form to create a new quest with tier selection, attribute assignment, and schedule |
| **Lockdown / Recovery** | Core Mechanic | Blocked-state UI when HP < 30%; recovery quest list with confirmation flow; clear lockdown on completion |
| **History Log** | Core UI | Audit trail of all `ActivityLog` entries with human-readable formatted messages |
| **Settings** | Core UI | App factory reset, lockdown recovery threshold configuration, debug options |
| **Data Seeding** | Backend | First-launch seed of `CharacterStat` rows with balanced starting values and default quests |
| **Missed Daily Penalty** | Backend | On-launch HP subtraction for skipped daily quests based on calendar-day gaps |
| **Lockdown Policy** | Core Mechanic | Pure rules for what's allowed during lockdown (quest creation, tier completion gates, recovery minimums) |
| **Quest Completion Service** | Backend | Authoritative transaction: eligibility check, XP grant, activity log insert, lockdown recovery tracking, rollback on failure |

---

## Planned Features (Priority Order)

### Phase 1: Onboarding & Customization

| Feature | Description | Rationale |
|---|---|---|
| **Onboarding Wizard** | First-launch flow: character name entry, avatar/appearance selection, attribute priority ranking. Feeds custom starting values into `DataSeedService`. | Users should be able to personalize their character and game feel before first quest. |
| **Stat Detail / Progression View** | Per-attribute drill-down: XP history graph, level milestones, activity sparkline over time. | Players want to understand and celebrate progress in their chosen attributes. |

### Phase 2: Backend Sync & Auth

| Feature | Description | Rationale |
|---|---|---|
| **Supabase Authentication** | Email/magic-link sign-up via Supabase Auth. Local-only mode (no account) remains fully functional. | Basis for cloud sync and multi-device support without forcing account creation. |
| **Supabase Sync** | Background sync of `UserProfile`, `Quest`, and `ActivityLog` to Postgres. Conflict resolution: last-write-wins per entity. Sync-status indicator in Settings. | Enable data backup, multi-device play, and server-side analytics without breaking offline-first UX. |

### Phase 3: Engagement & Streaks

| Feature | Description | Rationale |
|---|---|---|
| **Streak Tracker** | Daily login and quest-completion streaks per attribute. Bonus XP multiplier for sustained streaks (e.g., 7-day = 1.1x). Streak break feeds HP penalty. | Streaks drive habit formation; visible progress motivates daily return. |
| **Notifications** | Local `UserNotifications` for due daily quests and lockdown warnings. Per-quest and global Settings configuration. | Reminder system hooks into OS notification center; respects user's do-not-disturb preferences. |

### Phase 4: Content & Discovery

| Feature | Description | Rationale |
|---|---|---|
| **Quest Templates** | Pre-built quest packs per attribute (e.g., Fitness, Finance, Focus, Health). One-tap import. Stored as JSON bundles; applied via `DataSeedService`. | Reduce friction for new players; scaffold common quest types. |
| **Quest Categories & Tags** | User-defined and suggested categories (Work, Health, Learning, Fun). Filter and search by tag. | Organize quest library as it grows; support semantic grouping. |

### Phase 5: Platform Integration

| Feature | Description | Rationale |
|---|---|---|
| **Widget Extension** | Home/Lock screen widget: HP bar, active quest count, today's streak. Reads from shared `AppGroup` SwiftData store. | Persistent at-a-glance visibility; reinforces app value prop without opening the app. |
| **Screen Time Deep Integration** | Granular UI for blocked-app selection (beyond current all-or-nothing FamilyControls gate). Per-attribute lockdown profiles (e.g., block social media on Charisma lockdown). | Nuanced accountability: different attributes → different temptations. |

### Phase 6: Data & Export

| Feature | Description | Rationale |
|---|---|---|
| **Cloud Backup / Export** | One-tap export of `ActivityLog` and stat history as JSON or CSV. Independent of Supabase sync. | User owns their data; supports external analytics, archive, and transparency. |
| **Statistics Dashboard** | Aggregate stats: quests completed, total XP earned, average session time, attribute distribution. Trends over weeks/months. | Celebrate long-term progress and inform future goal-setting. |

### Phase 7: Social & Community (Stretch Goals)

| Feature | Description | Rationale |
|---|---|---|
| **Leaderboards** | Optional global/friend leaderboards (by XP, streaks, or quests completed). Privacy-respecting (opt-in). | Social proof and peer motivation; Supabase-backed. |
| **Quest Sharing** | Export and share quest templates with friends via deep links or JSON. Community hub (web) for popular templates. | Reduce duplicate work; build community around game mechanics. |
| **Daily Challenges** | Server-pushed optional daily quests (e.g., "Complete 3 Vitality quests today"). Bonus XP and streak multiplier. | Drive daily engagement; add structure and surprise. |

---

## Implementation Notes

### Execution Order

1. **Onboarding** and **Stat Detail** can be built immediately (no backend dependencies).
2. **Auth + Sync** unlock multi-device and backup; high priority for stability and user trust.
3. **Streaks** and **Notifications** amplify engagement without structural changes.
4. **Templates**, **Widget**, and **Screen Time** are semi-independent; parallelize as capacity allows.
5. **Export**, **Leaderboards**, and **Community** are nice-to-have; defer until core loops are proven.

### Architectural Readiness

- **MVVM-C pattern** already supports new features; add new `Features/<FeatureName>/` triads (View, ViewModel, Coordinator).
- **SwiftData models** may need new `@Model` classes (e.g., `Streak`, `Notification`, `QuestTemplate`); no migrations — fresh install required.
- **DependencyContainer** should be extended with new services (e.g., `StreakServiceProtocol`, `NotificationServiceProtocol`).
- **Supabase client** is registered but not yet wired; **Phase 2** integrates it into `SupabaseService` and adds background sync logic.

### Testing Strategy

- Unit tests for new services (Streak calculation, Notification scheduling, Template import).
- Integration tests for Supabase sync (mock Postgres responses, conflict resolution).
- UI tests for Onboarding and Widget Extension (using in-memory `ModelContainer`).
- Existing test framework (`@Test`, in-memory containers) applies to all new features.

---

## Open Questions

- **Notification Permissions:** Should we prompt for `UserNotifications` permission on first app launch or defer until first notification?
- **Sync Conflict Handling:** Last-write-wins is simple; should we consider finer granularity per model (e.g., preserve newer quests, overwrite older stats)?
- **Widget Refresh Cadence:** Real-time (via Live Activity) or on-demand snapshot (WidgetKit refresh cycle)?
- **Leaderboard Privacy:** Opt-in only, or anonymized by default?
