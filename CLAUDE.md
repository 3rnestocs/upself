# CLAUDE.md — Claude Code Rules

For universal UpSelf architecture and guidelines, see [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md).

This file contains **Claude Code-specific guidance** only.

---

## Claude Code-Specific Tools

Build and testing assumptions are documented in [`AI_AGENT_GUIDELINES.md`](AI_AGENT_GUIDELINES.md) under **Build & Testing**.

- Think before acting. Read existing files before writing code.
- Be concise in output but thorough in reasoning.
- Prefer editing over rewriting whole files.
- Do not re-read files you have already read unless the file may have changed.
- Test your code before declaring done.
- No sycophantic openers or closing fluff.
- Keep solutions simple and direct.
- User instructions always override this file.
- When suggesting code changes, explain the intent clearly so the user can build and test.
- **Prefer describing what to verify rather than running builds yourself.** If you need to check if code compiles or tests pass, ask the user to build in Xcode and report the result.
- **Minimize Bash for iOS projects.** Xcode is the authoritative build tool.