# Changelog

All notable changes to the **FountainSwiftPM** package are documented here. The manifest package name is **FountainSwiftPM**; library products include **Fountain**, **FountainCore**, **FountainHTML**, and **FountainUI**.

---

## Version axes (read this first)

| Axis | Meaning | Typical location |
|------|---------|------------------|
| **Fountain syntax / spec** | Which generation of the [Fountain markup](https://fountain.io/syntax/) format parsers target | ``FountainSyntaxPin/targetVersionLabel`` (e.g. **`"1.1"`**), ``FountainDocument/fountainSyntaxVersion`` in JSON |
| **Swift package (SemVer)** | API and distribution releases of **this repository** | ``FountainPackageVersion/librarySemanticVersion``, **git tags**, this file |

A **package** bump (e.g. to **2.0.0**) does **not** by itself change the Fountain **syntax** level; those are updated on their own schedules.

---

## [2.0.0] — 2026-04-11

SwiftPM **library** release **2.0.0**. Fountain **markup** target remains **1.1** (`FountainSyntaxPin.targetVersionLabel`).

### Breaking

- Removed **`Fountain/Legacy/`** (Objective-C + RegexKitLite reference tree). SwiftPM never compiled these files; they are gone from the repository (**Phase 14.2**).
- Removed the Swift **`FountainParser`** regex pipeline and **`FNParserType.regex`** / **`FNScript(…, parser: .regex)`**. Use **`FountainParsePipeline`** (**`.tokenPipeline`**, default) or **`FastFountainParser`** (**`.fast`**) (**Phase 14.3**).
- **`Package.swift`**: dropped **`Legacy`** from **`FountainCore`** / **`FountainHTML`** exclude lists (paths no longer exist).

### Added

- **`FountainPackageVersion`** — programmatic **package** SemVer string, distinct from **syntax** pin (**Phase 14.1**).
- **FountainUI** (Phase **13**): **`FountainView`**, **`FountainScriptElementTypography`**, **`FountainUIScriptElementLineContent`** — **Phase 13.3** wires **`FountainInlineMarkup.attributedFragment(from:)`** into SwiftUI **`Text`** for body-line kinds (character and scene-heading rows stay plain for cue casing / slug display).

---

## [Unreleased]

**Active epic:** **Phase 15** (polish) — [Fountain-1.1-Implementation-Roadmap.md](docs/Fountain-1.1-Implementation-Roadmap.md#phase-15).

### Planned

- **Phase 15.1** — SPM-native repository: remove **`Fountain.xcodeproj`**, migrate **Sample Project Mac/iOS** and **`FountainTests`** to SwiftPM-native targets (or a documented split repo), refresh CI and [Phase-1-Xcode-SPM-Integration.md](docs/Phase-1-Xcode-SPM-Integration.md) / **README** / **CONTRIBUTING**. *(Carried from the closed Phase 14 scope.)*

### Changed (polish)

- **Phase 15.2:** single catalog ``FountainPackageBundledFountainFixtures`` for all bundled **`.fountain`** fixtures — shared by **Phase 7** inventory and **fast** vs **tokenPipeline** parity tests; **Phase 7** inventory now includes **`export-golden-minimal`**.
- **Phase 15.3:** **`FountainView`** ImageRenderer regression test for **narrow proposed size** (layout stress); **`PackageFixtureCorpusTests`** asserts **`export-golden-minimal`** parse kinds.
- **Phase 15.4:** [Public-API-Surface.md](docs/Public-API-Surface.md) contributor note for bundled **`.fountain`** catalog; [SPM-Release-Checklist.md](docs/SPM-Release-Checklist.md) release step for new fixtures.
