# CLAUDE.md — Claude Code Rules

For universal UpSelf architecture and guidelines, see [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md).

This file contains **Claude Code-specific guidance** only.

---

## Build & Test

This is a native iOS project. **Build and run via Xcode** — there is no Makefile, fastlane, or npm.

**Do not invoke `xcodebuild` in the assistant flow** unless the user explicitly asks for a build to be run. Assume the user builds, runs, and tests **manually in Xcode**.

### Running Tests (CLI Reference)

When the user asks you to describe or suggest running tests, reference these commands (they may run them):

```bash
# All tests
xcodebuild test -scheme UpSelf -destination 'platform=iOS Simulator,name=iPhone 16'

# Single suite
xcodebuild test -scheme UpSelf -only-testing UpSelfTests/LockdownPolicyTests

# Single test
xcodebuild test -scheme UpSelf -only-testing UpSelfTests/LockdownPolicyTests/allows_createQuest_whenNotInLockdown
```

Tests use Apple's **Testing** framework (`@Test`, `#expect`) — not XCTest. In-memory `ModelContainer` per test.

---

## Claude Code Specifics

- **Prefer describing what to verify rather than running builds yourself.** If you need to check if code compiles or tests pass, ask the user to build in Xcode and report the result.
- **Use Read, Edit, Write, Glob, Grep tools** for code inspection and modification.
- **Minimize Bash for iOS projects.** Xcode is the authoritative build tool.
- When suggesting code changes, explain the intent clearly so the user can build and test.

---

## Secrets & Config

See [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md) under **Secrets Management**.

In short: `Secrets.template.xcconfig` → `Secrets.xcconfig` (gitignored), fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`. The build succeeds without it; Supabase calls are not yet wired at runtime.

---

## Referencing AI Guidelines

When you make code changes, implicitly follow the rules in [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md):
- MVVM-C architecture (Views/ViewModels/Coordinators)
- No `NavigationLink` for primary navigation
- `AppTheme` for all UI tokens
- `L10n` for all strings
- No SwiftData migrations
- `DependencyContainer` for services
- Small, scoped commits with `type(scope): summary` format
