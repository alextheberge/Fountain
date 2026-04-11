# Deprecation and distribution (Phases 0.3 & 1.2)

## Phase 1.2 — Package vs Xcode (complete)

- **SwiftPM (`Package.swift`)** defines **FountainCore**, **FountainHTML**, and umbrella **Fountain**; CI at the repo root is authoritative.
- **Library sources** live only under **`Fountain/`** (and **`Sources/Fountain/`** for the umbrella shim). There is no forked second codebase for the Swift library.
- **Xcode (`Fountain.xcodeproj`)** links the **local** Swift package for **Sample Project Mac**, **Sample Project iOS**, and **`FountainTests`** — those targets **do not** list `Fountain/*.swift` in **Compile Sources**. Library code is built once through SwiftPM. Details and rollback: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md).

---

## Phase 0.3 — Deprecation policy (decided)

This is the **baseline policy** for the Swift next-gen roadmap. It does not schedule removals; it tells contributors and app authors what to rely on.

| Asset | Status | Rule |
|-------|--------|------|
| **`FountainParsePipeline`** / **``.tokenPipeline``** | **Default** | **``FNScript``** sync, async, and stream entry points without an explicit **`parser:`** use the tokenizer-first pipeline (Phases **3–4**). New Fountain 1.1 behavior and parity tests target this path first. |
| **`FastFountainParser`** (**``.fast``**) | **Explicit opt-in** | Line-first engine for regression, benchmarks, or apps that still depend on its exact behavior. Not the default initializer path. |
| **`FountainParser`** (`FNParserType.regex`) | **Legacy Swift path** | Kept for apps that still depend on the regex pipeline. **Bugfixes only** unless a security or data-loss issue forces a larger change. No new Fountain 1.1 features are required to land here first. |
| **`Fountain/Legacy/*.m`** + **RegexKitLite** | **Out of package** | Not built by SwiftPM. **Reference-only.** No new development; do not extend for new syntax. |
| **Xcode vs SwiftPM** | **Single library graph (Phase 1.2)** | **CI and API truth** follow **`swift build` / `swift test`** on `Package.swift`. Xcode sample + test targets consume the **Fountain** package product from the same repo — [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md). |

**Feature flags:** The default `FNScript` initializers use **``.tokenPipeline``** (``FountainParsePipeline``). **`parser: .fast`** and **`parser: .regex`** are explicit; no separate feature flag is required.

**Hard cut:** There is **no** committed date to delete `FountainParser` or the Legacy folder. Revisit when a **major** semantic version documents breaking API/model changes (see [SPM-Release-Checklist.md](SPM-Release-Checklist.md)).

---

## Legacy Objective-C and RegexKitLite

- Sources under **`Fountain/Legacy/`** are **reference-only**. They are **not** compiled by SwiftPM (`Package.swift` excludes `Legacy/`).
- The **`FountainParser`** Swift class (regex pipeline) remains available via `FNScript(..., parser: .regex)` for compatibility. New features and bug fixes should target **`FountainParsePipeline`** / **``.tokenPipeline``** unless you are unblocking a legacy app (then **``.fast``** or **``.regex``** as appropriate).
- **RegexKitLite** and **`-licucore`** apply only if you build the old `.m` stack by hand. The Swift package path does not use them.

## Two ways to work with the same Swift sources

| Path | Use when |
|------|----------|
| **SwiftPM** (`Package.swift`) | Libraries, CI, package-first development (`swift build`, `swift test`). **Canonical** module graph for **`FountainCore`** / **`FountainHTML`** / umbrella **`Fountain`**. |
| **Xcode `Fountain.xcodeproj`** | Sample apps (**Sample Project Mac/iOS**) and **`FountainTests`**. Targets link the **local** **Fountain** product (see [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)); app/test host sources live outside the package tree paths above. |

### Xcode + local package (done)

See **[Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)** for verification steps, `@testable import` notes, and rollback if package wiring must be reverted.

**SPM** remains authoritative for API and CI; **library** edits are made under **`Fountain/`** and **`Package.swift`** only — Xcode picks them up through the package dependency.

## What “deprecated” means here

See **§ Phase 0.3** above for the authoritative rules. In short: nothing is **removed** yet. Legacy paths (`FountainParser` / RegexKitLite-era `.m`) get **bugfixes only** where necessary; prefer **`FountainCore`**, the default **tokenizer pipeline**, and **`FountainDocument`** for new work.

---

## Parser classification — Phase 4.6 (whitespace-only “action” lines)

**Change (Fountain 1.1 alignment):** A body line that contains **only** whitespace (two spaces, tabs, etc.) **outside** a dialogue block is **no longer** emitted as a standalone **`Action`** element. It is treated like a **blank** delimiter (same effect on slug / character rules as an empty line). **Inside** dialogue, whitespace-only lines still extend the dialogue block (including the historical **two-space** continuation rule).

**Migration:** If you relied on invisible “action” rows made only of spaces, switch to explicit forced action with **`!`** at the start of the line, or use real action text. Token-pipeline and fast parser stay aligned; see **`Phase46WhitespaceActionTests`** and roadmap **Phase 4.6**.
