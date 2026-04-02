# UpSelf: The Extreme Ownership RPG

UpSelf is an iOS application that gamifies discipline. It transforms daily responsibilities into RPG quests, tracks real-world attributes (Logistics, Mastery, Charisma, Willpower, Vitality, Economy), and enforces accountability by restricting access to distracting apps (via Screen Time API) when the user's "HP" drops below critical levels.

## Tech Stack

- **UI Framework:** SwiftUI
- **Routing:** UIKit (Coordinator Pattern)
- **Local Persistence:** SwiftData (Offline-First, Single Source of Truth)
- **Remote Database & Auth:** Supabase (PostgreSQL)
- **OS Integrations:** FamilyControls (Screen Time API)
- **Package Manager:** Swift Package Manager (SPM)

## Project Architecture: MVVM-C

This project strictly follows the Model-View-ViewModel-Coordinator pattern.

1. **Views (SwiftUI):** 100% declarative. NO business logic. NO `NavigationLink` or `NavigationStack` for main routing. All user intents delegate to ViewModel.
2. **ViewModels (Swift):** Handle presentation logic and local SwiftData mutations. Unaware of UI routing. Use Constructor Injection for dependencies. Emit navigation events via closures/delegates to the Coordinator.
3. **Coordinators (UIKit):** Manage `UINavigationController`. Resolve dependencies via DI Container/Property Wrappers, inject them into ViewModels, wrap SwiftUI Views in `UIHostingController`, and execute push/present.
4. **Data Flow:** Offline-first. UI reads exclusively from SwiftData. Supabase SDK handles background sync via auto-generated PostgREST APIs.

## Prerequisites

- Xcode 15.0+
- iOS 17.0+ Target
- **Apple Developer Program (paid)** if you use Screen Time / **Family Controls** — Personal Teams cannot provision the Family Controls capability; remove that capability in Xcode to build with a free account (the lockdown feature will not work until you use a paid membership and re-add the capability).

## Setup & Installation

1. Clone the repository.
2. Open `UpSelf.xcodeproj`.
3. Xcode will automatically resolve dependencies via SPM (`supabase-swift`).
4. Duplicate `.env.example` to `.env` and add your Supabase URL and Anon Key.
5. Build and run.

---

## 🤖 AI Agent Context (.cursorrules)

If you are an AI assistant helping with this project, strictly adhere to the following rules:

1. **Routing:** NEVER use `NavigationLink`, `NavigationStack`, or `@Environment(\.presentationMode)` for primary navigation. All routing must be handled by a UIKit Coordinator.
2. **Views:** SwiftUI views must delegate ALL actions to their `ViewModel`.
3. **Data Flow:** UI reads only from SwiftData (`@Query` or injected models). Do not call Supabase directly from the UI or ViewModel. Repositories handle the SwiftData <-> Supabase sync in the background.
4. **Scaffolding:** When asked to create a feature, always generate the triad: `[Feature]View.swift`, `[Feature]ViewModel.swift`, and wire it in the corresponding `Coordinator`.
