# Phase 1.2 — Xcode samples + local Swift package

Phase **1** is **complete** for SwiftPM: `Package.swift` is the canonical definition of **FountainCore**, **FountainHTML**, and umbrella **Fountain**, and CI runs `swift build` / `swift test` at the repo root.

The **Xcode** project (`Fountain.xcodeproj`) now references the **same** repository as an **`XCLocalSwiftPackageReference`** (path `.` from the project directory) and links the **Fountain** product into **Sample Project Mac**, **Sample Project iOS**, and **FountainTests**. Sample targets no longer list `Fountain/*.swift` in **Compile Sources**; library code is built only through SwiftPM.

## Why this setup

- Single compile path for library code in Xcode (fewer “forgot to add new file to pbxproj” mistakes).
- Sample apps behave like external consumers of the **Fountain** product.

## What was done (reference checklist)

1. **Local package:** repository root (folder containing `Package.swift`) is the Swift package; Xcode resolves **FountainSwiftPM** locally.
2. **Fountain** product is attached to **Sample Project Mac**, **Sample Project iOS**, and **FountainTests**.
3. **`Fountain/*.swift`** was removed from app targets’ **Compile Sources**; apps import **`Fountain`** where needed (`AppDelegate.swift`, `ViewController.swift`).
4. **Resources:** duplicate **`ScriptCSS.css`** copy steps were removed from Mac and iOS app bundles; CSS is loaded from **FountainHTML**’s `Bundle.module` (`#if SWIFT_PACKAGE` in `FNHTMLScript.swift`).
5. **Module name:** the Mac sample’s **`PRODUCT_MODULE_NAME`** is **`SampleProjectMac`** so it does not collide with the **`Fountain`** Swift module from the package; **`Application.xib`** sets **`customModule`** / **`customModuleProvider`** for **`AppDelegate`** accordingly.
6. **`FountainTests`** keeps **`@testable import Fountain`** with the package linked (works with current Xcode for this project).

**New Swift files** under `Fountain/` belong in **`Package.swift`** (and exclude lists for Core vs HTML); do not add them back to duplicate Xcode compile phases.

## Prerequisites

- **Same repo clone** used by Xcode and `swift test` (so `Package.swift` paths resolve).
- **Xcode 15+** (or the same major Swift as `swift-tools-version` in `Package.swift`) for local package support.
- After migration, **new Swift files** under `Fountain/` must be added only in **`Package.swift`** (and excluded lists if split between Core/HTML); Xcode targets must **not** list duplicate `Fountain/*.swift` sources.

## Quick verification

1. **Product → Clean Build Folder**, then build **Sample Project Mac** / **iOS**.
2. Run **FountainTests** from the Xcode scheme (or rely on **`swift test`** at repo root for CI parity).
3. Launch the sample app and open **Big Fish** (or a small `.fountain`) — HTML should still load from **`FountainHTML`**’s `Bundle.module` (`ScriptCSS.css`).

## Rollback

If package wiring breaks signing or resource lookup: remove the local package dependency from the affected targets, **re-add** `Fountain/*.swift` to **Compile Sources** from the project navigator (same paths as before Phase 1.2), restore **`ScriptCSS.css`** in the app targets’ **Copy Bundle Resources**, and revert **`PRODUCT_MODULE_NAME`** / **`Application.xib`** `customModule` for the Mac sample if you restore **`Fountain`** as the app module name.
