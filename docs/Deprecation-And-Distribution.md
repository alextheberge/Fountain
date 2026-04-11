# Deprecation and distribution (Phases 0.3 & 1.2)

## Legacy Objective-C and RegexKitLite

- Sources under **`Fountain/Legacy/`** are **reference-only**. They are **not** compiled by SwiftPM (`Package.swift` excludes `Legacy/`).
- The **`FountainParser`** Swift class (regex pipeline) remains available via `FNScript(..., parser: .regex)` for compatibility. New features and bug fixes should target **`FastFountainParser`** unless you are unblocking a legacy app.
- **RegexKitLite** and **`-licucore`** apply only if you build the old `.m` stack by hand. The Swift package path does not use them.

## Two ways to build the same Swift sources

| Path | Use when |
|------|----------|
| **SwiftPM** (`Package.swift`) | Libraries, CI, package-first development (`swift build`, `swift test`). Source of truth for **`FountainCore`** / **`FountainHTML`** / umbrella **`Fountain`**. |
| **Xcode `Fountain.xcodeproj`** | Sample apps (**Sample Project Mac/iOS**) and **`FountainTests`** hosted in the Mac sample. Targets compile **`Fountain/`** Swift files **inline** (not yet as an SPM dependency). |

### Wiring samples to the local package (future)

Migrating `.xcodeproj` to depend on the local package would simplify duplication but requires:

- Resolving **`FountainTests`** `@testable import` / host app **`PRODUCT_MODULE_NAME`** expectations.
- Ensuring **`ScriptCSS.css`** and **`Bundle.module`** behave the same for **`FountainHTML`** when linked as a package product.

Until that migration, treat **SPM** as authoritative for API and CI; keep Xcode changes in sync by editing the same files under **`Fountain/`**.

## What “deprecated” means here

Nothing is **removed** in a breaking way yet. **Deprecated** means: no new feature work on RegexKitLite parsers; prefer **`FountainCore`** APIs and **`FountainDocument`** for interchange.
