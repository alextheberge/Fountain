# Phase 1.2 — Swift Package (canonical) — **SPM-only** (Phase **15.1**)

The repository is **Swift Package Manager–native**: open **`Package.swift`** in Xcode (**File → Open…**) or work from the CLI with **`swift build`** / **`swift test`**. The legacy **`Fountain.xcodeproj`** and **Sample Project Mac/iOS** trees were **removed** in **Phase 15.1**; library sources live only under **`Fountain/`**, **`FountainUI/`**, **`Sources/Fountain/`**, and **`Package.swift`**.

## Products (unchanged)

- **`Fountain`** — umbrella (parse + HTML + writers).
- **`FountainCore`**, **`FountainHTML`**, **`FountainUI`** — as defined in **`Package.swift`**.

## Tests

- **`FountainPackageTests`** — primary SPM matrix (fixtures under **`Tests/FountainPackageTests/Fixtures/`**).
- **`FountainUIPackageTests`** — SwiftUI surface.
- **`FountainTests`** — legacy-style XCTest bundle from **`FountainTests/`** (fixtures under **`FountainTests/Resources/`**), **`@testable import Fountain`**, still run by **`swift test`** (no app host).

## macOS WKWebView sample

A minimal **AppKit + WKWebView** executable lives in the **nested** package **`Samples/FountainSampleMac/`** (depends on the repo root via **`../..`**):

```bash
cd Samples/FountainSampleMac
swift build
swift run FountainSampleMac
```

It bundles **`Big Fish.fountain`** and renders HTML with **`FNHTMLScript`**.

### iOS apps

There is no checked-in iOS sample app anymore. Depend on **`Fountain`** / **`FountainHTML`** from your own iOS app target (same as any Swift package), use **`WKWebView`**, and load HTML from **`FountainHTMLWriter`** or **`FNHTMLScript`** — mirror the macOS sample’s `viewDidLoad` pattern.

## Historical note (pre–15.1)

Older docs referred to **`Fountain.xcodeproj`** linking a local package into **Sample Project Mac/iOS** and hosted **FountainTests**. That wiring is **gone**; **`swift test`** at the repo root is the single CI and contributor path for the library.

## Rollback (if you must fork the old layout)

Restore **`Fountain.xcodeproj`** and sample targets from **git history** before the **15.1** merge commit; re-add **`Fountain/*.swift`** to duplicate compile phases only if you abandon SwiftPM as source of truth (not recommended).
