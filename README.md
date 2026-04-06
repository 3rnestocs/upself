# UpSelf: The Extreme Ownership RPG

UpSelf is an iOS app that gamifies discipline and self-improvement. Daily responsibilities become RPG quests. Real-world attributes (Logistics, Mastery, Charisma, Willpower, Vitality, Economy) are tracked as character stats. Accountability is enforced by restricting distracting apps via the Screen Time API when the user's HP drops into the critical zone (lockdown).

---

## Tech Stack

| Concern | Technology |
|---|---|
| UI | SwiftUI |
| Routing | UIKit — Coordinator Pattern |
| Local Persistence | SwiftData (offline-first, single source of truth) |
| Remote DB & Auth | Supabase (PostgreSQL) — client registered in DI; sync and auth not yet wired |
| OS Integration | FamilyControls (Screen Time API) |
| Package Manager | Swift Package Manager (SPM) |

**Fixed package versions:**

| Package | Source | Version |
|---|---|---|
| `supabase-swift` | https://github.com/supabase/supabase-swift.git | `2.5.1` (exact) |

---

## Requirements

| Tool | Minimum Version |
|---|---|
| Xcode | 26.0+ (last upgrade check: 26.3) |
| macOS (host) | 15.7 Sequoia |
| iOS (deployment target) | 26.2 |
| Swift | 5.0 |
| Apple Developer Account | Required — FamilyControls entitlement needs a provisioned device |

> FamilyControls cannot be tested in the Simulator. A real device with an active developer provisioning profile is required to exercise lockdown flows.

---

## Setup & Installation

1. Clone the repository.
2. Open `UpSelf.xcodeproj` in Xcode 26+.
3. Xcode resolves SPM dependencies automatically (`supabase-swift 2.5.1`).
4. Copy `Secrets.template.xcconfig` → `Secrets.xcconfig` (gitignored) and fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`. The build will succeed without this; Supabase calls are not yet wired at runtime.
5. Select a real device target (or simulator for non-FamilyControls flows) and build.

---

## Architecture: MVVM-C

```
Features/
├── Dashboard/          DashboardView + DashboardViewModel
├── QuestLog/           QuestLogView + QuestLogViewModel + QuestLogRowCard
├── CreateQuest/        CreateQuestView + CreateQuestViewModel
├── Lockdown/           RecoveryQuestListView + RecoveryQuestListViewModel
├── HistoryLog/         HistoryLogView + HistoryLogMessageFormatter
└── Settings/           SettingsView + SettingsViewModel

Core/
├── AppCoordinator.swift          Root UIKit coordinator; owns UITabBarController
├── AppConfig.swift               Reads Supabase credentials from Info.plist
├── DependencyContainer.swift     Service locator + @Injected property wrapper
├── GameClock.swift               Testable time source
├── L10n.swift                    String constants (EN + ES via Localizable.xcstrings)
├── Data/
│   ├── Models/                   UserProfile, Quest, CharacterStat, ActivityLog,
│   │                             CharacterAttribute, QuestRewardTier, ActivityLogKind,
│   │                             StatProgression
│   └── Services/                 DataSeedService, ActivityLogService,
│                                 QuestCompletionService, LockdownEvaluationService,
│                                 MissedDailyPenaltyService, LocalAppResetService
├── Lockdown/
│   ├── LockdownPolicy.swift      Pure rules: .allows(), .shouldClearLockdown()
│   └── LockdownCapability.swift  Enum of capabilities gated during lockdown
├── Network/
│   └── SupabaseService.swift     Supabase client wrapper (registered, not yet called)
└── Theme/
    └── AppTheme.swift            All UI tokens (colors, fonts, spacing)
```

### Layer boundaries

| Layer | Responsibility |
|---|---|
| **Views (SwiftUI)** | Declarative UI only. Read from `@Query` or ViewModel. Delegate all actions and navigation to closures. |
| **ViewModels (`@Observable`)** | Presentation state, SwiftData mutations, navigation intent via closures. Never own a navigation stack. |
| **Coordinators (UIKit)** | Own `UINavigationController` / `UITabBarController`. Push, present, pop, dismiss. Wrap SwiftUI in `UIHostingController`. |
| **Services** | Domain logic: seeding, lockdown evaluation, activity logging, daily penalties, reset, quest completion. |
| **Models (`@Model`)** | SwiftData entities. No business logic. |

**Navigation rule:** Never use `NavigationLink`, `NavigationStack`, or `@Environment(\.presentationMode)` for primary navigation. All routing goes through `AppCoordinator`. Deferred pushes use `DispatchQueue.main.async` to avoid UIKit/SwiftUI event-loop conflicts.

---

## Dependency Injection

`DependencyContainer` is a service locator. Access via subscript or `@Injected`:

```swift
let clock = DependencyContainer[\.gameClock]

@Injected(\.modelContainer) var container: ModelContainer
```

All registered services are protocol-backed for testability:

- `ModelContainer`
- `SupabaseServiceProtocol`
- `DataSeedServiceProtocol`
- `GameClock`
- `LocalAppResetServiceProtocol`
- `ActivityLogServiceProtocol`
- `LockdownEvaluationServiceProtocol`
- `QuestCompletionServiceProtocol`

---

## Key Design Rules

- **Offline-first.** SwiftData is the single source of truth. No Supabase calls from Views or ViewModels.
- **No SwiftData migrations.** Schema changes require a fresh install. Do not add `migrationPlan`.
- **`AppTheme` for all UI tokens.** No raw colors, fonts, or spacing values in views.
- **`L10n` for all user-visible strings.** No raw string literals in views; EN and ES are both maintained.
- **`GameClock` is the time source.** Inject it for anything time-dependent so tests can control time.
- **`LockdownPolicy.allows(_:isInLockdown:)`** is the single gate for lockdown-gated capabilities. Do not branch on HP state in views.

---

## Core Mechanics

### Quest Completion

`QuestCompletionService` is the authoritative transaction:

1. Eligibility check (lockdown tier gates, already-completed guard)
2. XP grant → stat update → level-up check
3. `ActivityLog` insert
4. Lockdown recovery counter increment (if in lockdown)
5. `ModelContext.save()` — or full rollback on failure

Returns `QuestCompletionResult`: `.completed`, `.completedAndClearedLockdown`, `.tierBlockedInLockdown`, `.notEligible`.

### Lockdown

HP below 30% triggers lockdown. During lockdown:
- Quest creation is blocked.
- Easy/Regular tier completions are blocked.
- Recovery requires Hard/Epic quests (default: 1 epic **or** 2 hard).

Logic is split across three files:
- `LockdownPolicy` — pure rules, no SwiftData
- `LockdownEvaluationService` — detects HP change → entry trigger
- `QuestCompletionService` — applies recovery completions and clears lockdown

### Missed Daily Penalty

`MissedDailyPenaltyService` runs on app launch and subtracts HP for missed daily quests based on calendar-day gaps. Uses `GameClock` so tests can simulate time passing.

---

## Testing

Tests use Apple's **Testing** framework (`@Test`, `#expect`) — not XCTest. In-memory `ModelContainer` instances are created per test; no shared state.

```bash
# All tests
xcodebuild test -scheme UpSelf -destination 'platform=iOS Simulator,name=iPhone 16'

# Single suite
xcodebuild test -scheme UpSelf -only-testing UpSelfTests/LockdownPolicyTests

# Single test
xcodebuild test -scheme UpSelf -only-testing UpSelfTests/LockdownPolicyTests/allows_createQuest_whenNotInLockdown
```

Existing suites: `LockdownPolicyTests`, `QuestCompletionHelpersTests`, `DataSeedServiceTests`, `MissedDailyPenaltyCalendarDayTests`, `HistoryLogMessageFormatterTests`.

---

## Secrets Management

Supabase credentials flow through xcconfig → build settings → `Info.plist` → `AppConfig.swift`.

1. Copy `Secrets.template.xcconfig` → `Secrets.xcconfig` (gitignored).
2. Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
3. `AppConfig.swift` reads them from `Info.plist` at runtime. Returns `nil` gracefully if missing; asserts only when `SupabaseService` is explicitly initialized.

---

## Roadmap & Implementation Status

See [`IMPLEMENTATION.md`](IMPLEMENTATION.md) for a detailed roadmap of shipped features and planned development phases.

---

## AI Agent Context

If you are an AI assistant working in this repo, read [`.cursorrules`](.cursorrules) and [`CLAUDE.md`](CLAUDE.md) at the repo root. They contain binding rules on navigation, theming, localization, SwiftData, and commit style that override any defaults.
