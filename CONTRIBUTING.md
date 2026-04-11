# Contributing to Fountain (Swift)

**Packaging:** Phase **1** (including **1.2**) is complete — prefer **`swift test`** at the repo root and **`Package.swift`** for library work. **`Fountain.xcodeproj`** links the **local** Swift package for **Sample Project Mac**, **Sample Project iOS**, and **`FountainTests`** (no duplicate compile of `Fountain/*.swift` in those targets). See [docs/Phase-1-Xcode-SPM-Integration.md](docs/Phase-1-Xcode-SPM-Integration.md) for verification and rollback.

## Parser and format regressions (Phase 7.4)

When you fix a bug in **`FastFountainParser`**, **`FountainWriter`**, or the **`FountainDocument`** mapping:

1. Add a **minimal** reproduction as a string (or tiny `.fountain` under `Tests/FountainPackageTests/Fixtures/` when shared across tests). If you add a fixture file, extend **`Phase7ComplianceTests.testBundledFixtureInventory`** so the inventory stays accurate.
2. Add or extend an SPM test in **`Tests/FountainPackageTests/`** (e.g. `SpecTraceabilityTests`, `Phase5ProductionFeaturesTests`, `Phase7ComplianceTests`) so `swift test` catches the regression.
3. Update **`docs/Fountain-1.1-Implementation-Roadmap.md`** spec traceability or phase tables if the change affects Fountain 1.1 coverage notes.
4. Update **`docs/Fountain-1.1-Gap-Analysis.md`** if the change touches the feature matrix, fixture map, or “living baseline” narrative.

**FDX export shape:** If you change **`FountainFDXWriter`**, update **`Tests/FountainPackageTests/Fixtures/export-golden-minimal.fdx`** in the same PR so **`ExportGoldenFixtureTests`** stays green unless the change is intentional across the team.

**Third-party test cases:** see [docs/External-Fountain-Test-References.md](docs/External-Fountain-Test-References.md) (Phase 7.3) before copying tests into the repo.

Keep Xcode **`FountainTests`** and SPM tests aligned when behavior changes; prefer the same fixture text in both places when practical.

## Before opening a PR

- Run **`swift build`** and **`swift test`** from the repository root.
- If you use the Xcode project, build **Sample Project Mac** (and tests if you touched shared sources).
- Optional: after deep parser changes, run the **Wasm: FountainCore** workflow (Actions tab) or see [docs/SwiftWasm-Experimental.md](docs/SwiftWasm-Experimental.md).

## Code style

Match surrounding files: naming, access control, and comment density. Avoid drive-by refactors unrelated to your change.
