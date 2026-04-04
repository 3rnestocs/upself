# UpSelf: The Extreme Ownership RPG

UpSelf is an iOS application that gamifies discipline. It transforms daily responsibilities into RPG quests, tracks real-world attributes (Logistics, Mastery, Charisma, Willpower, Vitality, Economy), and enforces accountability by restricting access to distracting apps (via Screen Time API) when the user's "HP" drops below critical levels.

## Tech Stack

- **UI Framework:** SwiftUI
- **Routing:** UIKit (Coordinator Pattern)
- **Local Persistence:** SwiftData (Offline-First, Single Source of Truth)
- **Remote Database & Auth:** Supabase (PostgreSQL) — **client is included and registered in DI; background sync and auth are not wired in the app yet**
- **OS Integrations:** FamilyControls (Screen Time API)
- **Package Manager:** Swift Package Manager (SPM)

## Project Architecture: MVVM-C

This project follows the Model-View-ViewModel-Coordinator pattern.

1. **Views (SwiftUI):** Declarative UI. Primary navigation does not use `NavigationLink` / `NavigationStack` — the coordinator owns `UINavigationController` and pushes `UIHostingController` roots.
2. **ViewModels:** Presentation logic and SwiftData mutations the feature owns. No UIKit routing; communicate navigation via callbacks to the coordinator.
3. **Coordinators (UIKit):** Manage stacks, inject dependencies, and perform push/present.
4. **Data flow:** Offline-first. Screens read from SwiftData. **Remote sync:** When implemented, it should live in services/repositories — not in Views or ViewModels (see `SupabaseService` / `DependencyContainer`).

## Configuration

- **Supabase URL and anon key** are defined in `UpSelf/Core/AppConfig.swift` for this repo snapshot. They feed `SupabaseService` via `DependencyContainer`. There is **no** runtime `.env` loader yet; if you add one later, update `AppConfig` (or a build setting) and keep **README** in sync.

## Prerequisites

- Xcode 15.0+
- iOS 17.0+ Target (see the Xcode project for the exact deployment version)
- Active Apple Developer Account (Required for FamilyControls entitlement)

## Setup & Installation

1. Clone the repository.
2. Open `UpSelf.xcodeproj`.
3. Xcode will automatically resolve dependencies via SPM (`supabase-swift`).
4. Build and run.

Unit tests live under `UpSelfTests/` (e.g. lockdown policy, quest completion helpers, seed idempotency).

---

## AI Agent Context (.cursorrules)

If you are an AI assistant helping with this project, strictly adhere to the rules in [`.cursorrules`](.cursorrules) at the repo root (coordinator-only primary navigation, `AppTheme` / `L10n`, no SwiftData migrations unless explicitly requested, etc.).
