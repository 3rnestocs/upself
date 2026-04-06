# CLAUDE.md — Claude Code Rules

For universal UpSelf architecture and guidelines, see [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md).

This file contains **Claude Code-specific guidance** only.

---

## Claude Code-Specific Tools

Build and testing assumptions are documented in [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md) under **Build & Testing**.

- **Prefer describing what to verify rather than running builds yourself.** If you need to check if code compiles or tests pass, ask the user to build in Xcode and report the result.
- **Use Read, Edit, Write, Glob, Grep tools** for code inspection and modification.
- **Minimize Bash for iOS projects.** Xcode is the authoritative build tool.
- When suggesting code changes, explain the intent clearly so the user can build and test.

