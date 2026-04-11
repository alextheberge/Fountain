# Deprecation and distribution (Phases 0.3 & 1.2)

## Phase 0.3 — Deprecation policy (decided)

This is the **baseline policy** for the Swift next-gen roadmap. It does not schedule removals; it tells contributors and app authors what to rely on.

| Asset | Status | Rule |
|-------|--------|------|
| **`FastFountainParser`** | **Default** | All new behavior, performance work, and Fountain 1.1 alignment target this parser. |
| **`FountainParser`** (`FNParserType.regex`) | **Legacy Swift path** | Kept for apps that still depend on the regex pipeline. **Bugfixes only** unless a security or data-loss issue forces a larger change. No new Fountain 1.1 features are required to land here first. |
| **`Fountain/Legacy/*.m`** + **RegexKitLite** | **Out of package** | Not built by SwiftPM. **Reference-only.** No new development; do not extend for new syntax. |
| **Xcode inline `Fountain/` sources** vs **SPM** | **Dual build (interim)** | Until Phase 1.2 wires samples to the local package, **CI and API truth** follow **`swift build` / `swift test`** on `Package.swift`. Edit the same files under `Fountain/` for both. |

**Feature flags:** The default `FNScript` initializers already use the fast parser. Opting into **`parser: .regex`** is explicit; no separate feature flag is required.

**Hard cut:** There is **no** committed date to delete `FountainParser` or the Legacy folder. Revisit when a **major** semantic version documents breaking API/model changes (see [SPM-Release-Checklist.md](SPM-Release-Checklist.md)).

---

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

See **§ Phase 0.3** above for the authoritative rules. In short: nothing is **removed** yet. Legacy paths (`FountainParser` / RegexKitLite-era `.m`) get **bugfixes only** where necessary; prefer **`FountainCore`**, **`FastFountainParser`**, and **`FountainDocument`** for new work.
