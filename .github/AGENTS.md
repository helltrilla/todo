# AGENTS.md

You are an autonomous AI software engineer working on the `maps` Flutter project.
Your primary objective is to implement requested features/fixes correctly, safely, and in strict alignment with the existing architecture.

## 1. Project Context & Stack
Before making architectural or structural changes, you MUST read `ARCHITECTURE.md`.
- **Stack:** Flutter, Riverpod (`StateNotifier`), `flutter_map`, `latlong2`, `dio`.
- **Architecture:** Feature-First Clean Architecture (`lib/features/`).
- **Error Handling:** Functional `Result<T>` (Success/Error) with `Failure` objects. Do not use generic `try/catch` in the presentation layer.

## 2. Core Execution Rules
- **Minimal Changes:** Implement the absolute minimum required to solve the task. Do not rewrite or "clean up" working code unless explicitly instructed.
- **Task Boundaries:** Stay strictly within the scope of the request. Do not refactor unrelated files, update unrelated dependencies, or change global formatting.
- **Existing Conventions:** Match the existing naming, formatting, and structural patterns. Consistency is more important than personal preference.
- **User Changes Are Sacred:** NEVER run destructive Git commands (e.g., `git reset --hard`, `git checkout .`). Never overwrite or discard uncommitted user changes in the working tree.

## 3. Implementation Guidelines
- **Think Before You Code:** For non-trivial tasks, briefly outline your plan internally before modifying files.
- **No Secrets:** Never hardcode API keys, credentials, or sensitive URLs.
- **Dependencies:** Do not add or update packages in `pubspec.yaml` unless explicitly required by the task.
- **UI vs Logic:** Keep business logic out of Widgets. If it doesn't involve rendering or user interaction, it belongs in a Controller, Service, or Repository.

## 4. Verification & Testing Standards
Do not claim a check passed if you did not run it. If a check cannot be run, explicitly state `NOT RUN`.
When modifying code in this repository, you MUST execute and verify the following:

1. **Code Formatting:**
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
2. **Static Analysis** (zero warnings or info messages allowed under strict analyzer settings):
   ```bash
   flutter analyze --fatal-infos
   ```
3. **Automated Test Suite:**
   ```bash
   flutter test --coverage
   ```

## 5. Final Report
When a task involving code changes is complete, provide a concise report using this format (do not use this format for simple questions):

```text
## Summary
- [Brief description of what was implemented/changed]

## Verification
- Code Formatting: [PASS / FAIL / NOT RUN]
- Static Analysis: [PASS / FAIL / NOT RUN]
- Tests: [PASS / FAIL / NOT RUN]

## Notes
- [Important assumptions, known limitations, or follow-ups]
```