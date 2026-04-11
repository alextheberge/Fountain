# Changelog

All notable changes to the **FountainSwiftPM** package are documented here. The manifest package name is **FountainSwiftPM**; library products include **Fountain**, **FountainCore**, **FountainHTML**, and **FountainUI**.

## [Unreleased]

### Breaking

- Removed **`Fountain/Legacy/`** (Objective-C + RegexKitLite reference tree). SwiftPM never compiled these files; they are gone from the repository (**Phase 14.2**).
- Removed the Swift **`FountainParser`** regex pipeline and **`FNParserType.regex`** / **`FNScript(…, parser: .regex)`**. Use **`FountainParsePipeline`** (**`.tokenPipeline`**, default) or **`FastFountainParser`** (**`.fast`**) (**Phase 14.3**).
- **`Package.swift`**: dropped **`Legacy`** from **`FountainCore`** / **`FountainHTML`** exclude lists (paths no longer exist).

### Added

- **FountainUI** (Phase **13**): **`FountainView`**, **`FountainScriptElementTypography`**, **`FountainUIScriptElementLineContent`** — **Phase 13.3** wires **`FountainInlineMarkup.attributedFragment(from:)`** into SwiftUI **`Text`** for body-line kinds (character and scene-heading rows stay plain for cue casing / slug display).

### Not yet in this release train

- **Phase 14.4**: removing **`Fountain.xcodeproj`** and migrating sample apps to SPM-only workflows remains open.
