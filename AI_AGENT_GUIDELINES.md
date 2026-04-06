# UpSelf — AI Agent Guidelines

**For Claude Code:** See [`CLAUDE.md`](CLAUDE.md)  
**For Cursor:** See [`.cursorrules`](.cursorrules)  
**For other tools:** This file contains all shared rules.

---

## Project Summary

**UpSelf** is an RPG-style life productivity iOS app. Daily responsibilities become quests. Real-world attributes (Logistics, Mastery, Charisma, Willpower, Vitality, Economy) are tracked as character stats (HP, XP, leveling). Accountability is enforced by restricting distracting apps via the Screen Time API when HP drops into the critical zone (lockdown).

**Stack:**
- UI: SwiftUI + UIKit Coordinators for navigation
- Persistence: SwiftData (offline-first, single source of truth)
- Remote: Supabase (PostgreSQL, sync/auth not yet wired to UI)
- SPM for dependencies
- FamilyControls (Screen Time API)

**Deployment target:** iOS 26.2; Xcode 26.0+; Swift 5.0; macOS 15.7 (host).

---

## Architecture: MVVM-C

The app strictly follows **Model-View-ViewModel-Coordinator** pattern:

1. **Views (SwiftUI):** Declarative UI only. No business logic. User actions delegate to **ViewModel**. State comes from **SwiftData** (`@Query`, environment) or ViewModel-owned presentation state.

2. **ViewModels (`@Observable`):** Presentation logic and SwiftData mutations for the feature. **No UIKit routing**. Expose navigation intent via closures/callbacks for the Coordinator.

3. **Coordinators (UIKit):** Own `UINavigationController` / `UITabBarController`. Create `UIHostingController` roots. Push, present, pop, dismiss. Inject dependencies into ViewModels.

4. **Data Layer:** Offline-first. Screens read from SwiftData. **Do not call Supabase from Views or ViewModels** — sync/auth belongs in services/repositories when introduced.

5. **DI:** Use **`DependencyContainer`** + **`@Injected`** for shared services (`ModelContainer`, seeding, Supabase, `GameClock`, etc.).

### Navigation (Strict Rules)

- **Never** use `NavigationLink`, `NavigationStack`, or `@Environment(\.presentationMode)` for **primary app navigation**.
- **All routing goes through `AppCoordinator`** (or feature coordinators) + `UIHostingController`.
- **Do not** call `pushViewController`, `popViewController`, `present`, `dismiss`, or similar on the app's `UINavigationController` from Views, ViewModels, or helpers. Add a method on `AppCoordinator`, build the `UIHostingController` there, and perform the transition there.
- Use deferred helpers (e.g., `DispatchQueue.main.async`) when the entry point is SwiftUI to avoid UIKit/SwiftUI event-loop conflicts.
- **SwiftUI-only sheets** (local `.sheet`, small overlays) may stay on the View if they are **not** part of app-level stack navigation.

---

## Folder Structure & Naming

```
UpSelf/
├── AppCoordinator.swift              Root UIKit coordinator
├── UpSelfApp.swift                   App entry point
├── Core/
│   ├── AppConfig.swift               Supabase config (Info.plist)
│   ├── DependencyContainer.swift     Service locator + @Injected
│   ├── GameClock.swift               Testable time source
│   ├── L10n.swift                    String constants (EN + ES)
│   ├── Data/
│   │   ├── Models/                   UserProfile, Quest, CharacterStat, ActivityLog, etc.
│   │   └── Services/                 DataSeedService, QuestCompletionService, etc.
│   ├── Lockdown/
│   │   ├── LockdownPolicy.swift      Pure rules
│   │   └── LockdownCapability.swift  Enum of capabilities gated during lockdown
│   ├── Network/
│   │   └── SupabaseService.swift     Supabase client (registered, not yet called from UI)
│   ├── Theme/
│   │   └── AppTheme.swift            UI tokens (colors, fonts, spacing)
│   └── UI/                           Reusable UI helpers
└── Features/
    ├── Dashboard/
    ├── QuestLog/
    ├── CreateQuest/
    ├── Lockdown/
    ├── HistoryLog/
    └── Settings/
```

**File naming:**
- Types & files: **PascalCase** (`DashboardView.swift`, `UserProfile.swift`)
- SwiftData models & enums: clear, stable names (e.g., `CharacterAttribute`, not magic strings)

**Feature structure (the "triad"):**
```
Features/<FeatureName>/
├── <FeatureName>View.swift
├── <FeatureName>ViewModel.swift
└── (optional local helpers)
```

Wire entry in `AppCoordinator`, injecting dependencies.

---

## Theme & Visuals (`AppTheme`)

**Single source of truth:** `Core/Theme/AppTheme.swift` — all colors, fonts, spacing, radii, strokes, shadows, bar heights, etc.

**Rules:**
- **Do not** scatter raw hex colors, magic `CGFloat` padding/radius, or ad hoc `Font.custom` calls in views.
- Use `AppTheme.Colors.*`, `AppTheme.Fonts.*`, `AppTheme.Spacing.*`, `AppTheme.Radius.*`, etc.
- **Semantic palette (Amber Terminal):** background `#121212`, cards `#242424`, accent/XP `#FFB000`, alert/HP danger `#FF4500`.
- Custom fonts (e.g., Quantico) configured **once** in `AppTheme.Fonts`; views call `AppTheme.Fonts.ui(...)` / `mono(...)`.

---

## Localization (`L10n`)

**All user-visible strings go through `L10n`.**

- Strings live in **`Localizable.xcstrings`** (EN + ES).
- Typed accessors in **`Core/L10n.swift`** (e.g., `L10n.App.*`, `L10n.Stats.*`, `L10n.HUD.*`).
- Views/ViewModels use `L10n.*` — **not** `String(localized:)` or raw keys.
- Keep stat names aligned with `CharacterAttribute` + `L10n.Stats`.

---

## Data & Domain

**SwiftData models:**
- Live under `Core/Data/Models/` (`UserProfile`, `Quest`, `CharacterStat`, `ActivityLog`, etc.).
- Use enums (`CharacterAttribute`, `QuestRewardTier`, `ActivityLogKind`) for fixed value sets; persist stable `rawValue`s.

**Seeding:** `DataSeedService` (first-launch, idempotent). Keep out of Views.

**No migrations or compatibility shims:**
- **Do not** add SwiftData migration plans, `@Attribute(originalName:)` renames, or legacy-rewrite services.
- If schema or core models change: **delete the app / fresh install with new models**.
- Do not invest in upgrade paths unless explicitly requested.

---

## Dependency Injection

`DependencyContainer` is a service locator. Access via subscript or property wrapper:

```swift
let clock = DependencyContainer[\.gameClock]

@Injected(\.modelContainer) var container: ModelContainer
```

**Registered services (all protocol-backed for testability):**
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

- **Offline-first:** SwiftData is the single source of truth. No Supabase calls from Views or ViewModels.
- **No SwiftData migrations:** Schema changes = fresh install.
- **`AppTheme` for all UI tokens** — no raw colors, fonts, spacing in views.
- **`L10n` for all user-visible strings** — no raw string literals in views.
- **`GameClock` is the time source.** Inject it for anything time-dependent so tests can control time.
- **`LockdownPolicy.allows(_:isInLockdown:)` is the single gate** for lockdown-gated capabilities. Do not branch on HP state in views.

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

Logic split across three files:
- `LockdownPolicy` — pure rules, no SwiftData
- `LockdownEvaluationService` — detects HP change → entry trigger
- `QuestCompletionService` — applies recovery completions and clears lockdown

### Missed Daily Penalty

`MissedDailyPenaltyService` runs on app launch and subtracts HP for missed daily quests based on calendar-day gaps. Uses `GameClock` so tests can simulate time passing.

### ViewModels: Separation of Concerns

ViewModels separate presentation logic from Views. Examples:
- `DashboardViewModel`: Refresh state (`stats`, `profile`, `xpToNext`), actions (`completeQuest()`, `showCreateQuestModal()`), navigation callbacks (`onNavigateToQuestLog`)
- `QuestLogViewModel`: Display filtering (completed vs. ongoing), row state (can complete, is completed), actions with result handling
- `RecoveryQuestListViewModel`: Separate VM for lockdown recovery path; owns confirmation + lockdown-cleared callbacks

Views receive data from VMs, trigger actions via closures, never own navigation. ViewModels call services or mutate SwiftData, then expose navigation intent via closures.

---

## Testing

Tests use Apple's **Testing** framework (`@Test`, `#expect`) — **not** XCTest.

- In-memory `ModelContainer` per test; no shared state.
- Existing suites: `LockdownPolicyTests`, `QuestCompletionHelpersTests`, `DataSeedServiceTests`, `MissedDailyPenaltyCalendarDayTests`, `HistoryLogMessageFormatterTests`.

See `CLAUDE.md` for command-line test invocations.

---

## Secrets Management

Supabase credentials flow: xcconfig → build settings → `Info.plist` → `AppConfig.swift`.

1. Copy `Secrets.template.xcconfig` → `Secrets.xcconfig` (gitignored).
2. Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
3. `AppConfig` reads from `Info.plist` at runtime; returns `nil` gracefully if missing.

---

## Code Style for AI Edits

- **Match existing style:** imports, naming, abstraction level in the touched area.
- **Minimal diffs:** change only what the task requires; no drive-by refactors.
- **Do not** add unsolicited documentation files unless asked.
- **Small, focused commits:** one logical change per commit (see Git section below).

---

## Git: Branches & Commits

**Goal:** Readable history, small reviewable units, modular changes — avoid large catch-all commits.

### Branches

- **Short-lived topic branches** per task or coherent slice of work.
- **Suggested prefixes:**
  - `feature/<short-name>` — new behavior (e.g., `feature/quest-list`)
  - `fix/<short-name>` — bugfixes
  - `chore/<short-name>` — tooling, deps, non-product refactors
- **Merge to main** when the branch represents one completed story/fix.

### Commits

- **One logical change per commit** (one concern: e.g., theme tokens only, L10n only, one feature file).
- **Format:** `type(scope): summary`
  - **Types:** `feat`, `fix`, `refactor`, `style` (UI-only), `docs`, `chore`, `test`
  - **Scope:** `dashboard`, `theme`, `l10n`, `data`, `coordinator`, `deps`, etc.
  - **Examples:**
    - `feat(dashboard): add stat grid layout`
    - `fix(l10n): correct Spanish stat label`
    - `refactor(theme): centralize bar heights in AppTheme`
    - `test(lockdown): add recovery edge-case test`
- **Subject line:** single line, ~72 chars, imperative mood ("Add", "Fix", "Refactor").
- **Body** optional; use when the *why* isn't obvious. Keep commits **small** enough that the subject suffices most of the time.
- **Do not mix unrelated edits** (e.g., don't combine a feature with a dependency bump in the same commit).

---

## Checklist Before Finishing a Task

- [ ] No `NavigationLink` / primary `NavigationStack` routing introduced.
- [ ] No direct `UINavigationController` push/pop/present outside `AppCoordinator` for primary flows.
- [ ] Colors/spacing/fonts from `AppTheme`.
- [ ] Strings from `L10n` + `Localizable.xcstrings`.
- [ ] SwiftData reads in Views via `@Query` where appropriate.
- [ ] If committing: small, scoped commits with one-line subjects (`type(scope): summary`).
- [ ] No new SwiftData migration / legacy-store logic — schema changes = fresh install.
