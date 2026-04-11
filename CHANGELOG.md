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

## [2.0.1] — 2026-04-11

**Integrator readiness:** documentation, **README** SwiftPM–first guidance, and automated checks for **export** and **parser** consistency. **No intentional public API removals** (patch). Fountain **markup** target remains **1.1** (`FountainSyntaxPin.targetVersionLabel`).

### Changed

- **Phase 15.2:** single catalog ``FountainPackageBundledFountainFixtures`` for bundled **`.fountain`** files — shared by **Phase 7** inventory, **fast** vs **tokenPipeline** parity, and **Phase 4** ``FountainScriptElementsBuilder`` vs default parser parity; **Phase 7** inventory includes **`export-golden-minimal`**.
- **Phase 15.3:** ``ExportGoldenFixtureTests`` — **FDX**, **HTML**, and **``FountainDocument``** semantics match across **`.fast`** and **``.tokenPipeline``** for **`export-golden-minimal`**; **`FountainView`** narrow **ImageRenderer** test; **`PackageFixtureCorpusTests`** kind sequence for golden minimal.
- **Phase 15.4:** [Public-API-Surface.md](docs/Public-API-Surface.md) fixture contributor note; [SPM-Release-Checklist.md](docs/SPM-Release-Checklist.md) step for new fixtures; [docs/Deprecation-And-Distribution.md](docs/Deprecation-And-Distribution.md) / [docs/Fountain-1.1-Gap-Analysis.md](docs/Fountain-1.1-Gap-Analysis.md) **Phase 4.6** migration pointers.
- **``FountainPackageVersion.librarySemanticVersion``** → **`2.0.1`**.

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

**Planned:** **Phase 15.1** — SPM-native repository (remove **`Fountain.xcodeproj`**, migrate samples / **`FountainTests`**) — [Fountain-1.1-Implementation-Roadmap.md](docs/Fountain-1.1-Implementation-Roadmap.md#phase-15).
