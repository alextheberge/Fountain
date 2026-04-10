# Contributing to Fountain (Swift)

## Parser and format regressions (Phase 7.4)

When you fix a bug in **`FastFountainParser`**, **`FountainWriter`**, or the **`FountainDocument`** mapping:

1. Add a **minimal** reproduction as a string (or tiny `.fountain` under `Tests/FountainPackageTests/Fixtures/` when shared across tests).
2. Add or extend an SPM test in **`Tests/FountainPackageTests/`** (e.g. `SpecTraceabilityTests`, `Phase5ProductionFeaturesTests`) so `swift test` catches the regression.
3. Update **`docs/Fountain-1.1-Implementation-Roadmap.md`** spec traceability or phase tables if the change affects Fountain 1.1 coverage notes.

Keep Xcode **`FountainTests`** and SPM tests aligned when behavior changes; prefer the same fixture text in both places when practical.

## Before opening a PR

- Run **`swift build`** and **`swift test`** from the repository root.
- If you use the Xcode project, build **Sample Project Mac** (and tests if you touched shared sources).

## Code style

Match surrounding files: naming, access control, and comment density. Avoid drive-by refactors unrelated to your change.
