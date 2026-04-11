# Phase 1.2 follow-up — Xcode samples + local Swift package (optional)

Phase **1** is **complete** for SwiftPM: `Package.swift` is the canonical definition of **FountainCore**, **FountainHTML**, and umbrella **Fountain**, and CI runs `swift build` / `swift test` at the repo root.

The **Xcode** project (`Fountain.xcodeproj`) still compiles the same `Fountain/*.swift` files **into the sample app targets** (not as a separate framework target). That keeps **one filesystem tree** but **two build graphs** (SPM vs Xcode). This document is for contributors who want to **link the local package** from Xcode later and drop duplicate compilation.

## Why migrate

- Single compile path for library code in Xcode (fewer “forgot to add new file to pbxproj” mistakes).
- Sample apps behave like external consumers of the **Fountain** product.

## Rough migration checklist

1. In Xcode: **File → Add Package Dependencies… → Add Local…** and select the repository root (the folder containing `Package.swift`).
2. Add the **Fountain** product to **Sample Project Mac**, **Sample Project iOS**, and **FountainTests** (or **FountainCore** only if you split tests).
3. **Remove** all `Fountain/*.swift` entries from each app target’s **Compile Sources** (keep only `AppDelegate.swift`, `ViewController.swift`, etc.).
4. **Resources:** `ScriptCSS.css` is bundled via **FountainHTML**’s `Bundle.module` when built as SPM; today the Mac sample also copies `ScriptCSS.css` into the app bundle. After migration, prefer loading CSS from the **FountainHTML** resource bundle (or keep a thin copy in the app if you need `Bundle.main` compatibility during transition).
5. **`FountainTests`** uses `@testable import Fountain`. After linking the package, confirm the test target’s dependency enables **testable** access in your Xcode version (local packages usually support this for debug test runs). If not, switch tests to `import Fountain` and test only public API, or move remaining tests into **`Tests/FountainPackageTests/`** under SPM.

Until this migration is done, **editing `Fountain/*.swift` once** still updates both SPM and Xcode, because both compile the same paths.
