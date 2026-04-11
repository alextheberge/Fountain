# Deprecation and distribution (Phases 0.3 & 1.2)

**Version axes:** **Fountain syntax 1.1** (``FountainSyntaxPin``, JSON ``fountainSyntaxVersion``) is independent of **Swift package SemVer** (``FountainPackageVersion``, git tags, [CHANGELOG.md](../CHANGELOG.md)). A **2.0.0** library release does not imply Fountain **2.0** markup.

## Phase 1.2 — Package vs Xcode (complete)

- **SwiftPM (`Package.swift`)** defines **FountainCore**, **FountainHTML**, and umbrella **Fountain**; CI at the repo root is authoritative.
- **Library sources** live only under **`Fountain/`** (and **`Sources/Fountain/`** for the umbrella shim). There is no forked second codebase for the Swift library.
- **Xcode (`Fountain.xcodeproj`)** links the **local** Swift package for **Sample Project Mac**, **Sample Project iOS**, and **`FountainTests`** — those targets **do not** list `Fountain/*.swift` in **Compile Sources**. Library code is built once through SwiftPM. Details and rollback: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md).

---

## Phase 0.3 — Deprecation policy (decided)

This is the **baseline policy** for the Swift next-gen roadmap. Breaking removals are listed in **[CHANGELOG.md](../CHANGELOG.md)** and tagged on **`main`** per [SPM-Release-Checklist.md](SPM-Release-Checklist.md).

| Asset | Status | Rule |
|-------|--------|------|
| **`FountainParsePipeline`** / **``.tokenPipeline``** | **Default** | **``FNScript``** sync, async, and stream entry points without an explicit **`parser:`** use the tokenizer-first pipeline (Phases **3–4**). New Fountain 1.1 behavior and parity tests target this path first. |
| **`FastFountainParser`** (**``.fast``**) | **Explicit opt-in** | Line-first engine for regression, benchmarks, or apps that still depend on its exact behavior. Not the default initializer path. |
| **Xcode vs SwiftPM** | **Single library graph (Phase 1.2)** | **CI and API truth** follow **`swift build` / `swift test`** on `Package.swift`. Xcode sample + test targets consume the **Fountain** package product from the same repo — [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md). |

**Removed (Phase 14.2–14.3, pre-`2.0.0` tag):** **`Fountain/Legacy/`** (Objective-C + RegexKitLite reference tree) and the Swift **`FountainParser`** pipeline / **`FNParserType.regex`**. Consumers that still need RegexKitLite-era sources must vendor them from git history.

**Feature flags:** The default `FNScript` initializers use **``.tokenPipeline``** (``FountainParsePipeline``). **`parser: .fast`** is explicit; no separate feature flag is required.

---

## Legacy Objective-C and RegexKitLite (removed from tree)

- **`Fountain/Legacy/`** has been **deleted** from the repository. **SwiftPM** never compiled it; archived copies may exist in **git history** or forks.
- **`FountainRegexes.swift`** and **`String+Regex.swift`** remain for **HTML** export, inline markup, and related string helpers — not for a second full-document Swift parser.

## Two ways to work with the same Swift sources

| Path | Use when |
|------|----------|
| **SwiftPM** (`Package.swift`) | Libraries, CI, package-first development (`swift build`, `swift test`). **Canonical** module graph for **`FountainCore`** / **`FountainHTML`** / umbrella **`Fountain`**. |
| **Xcode `Fountain.xcodeproj`** | Sample apps (**Sample Project Mac/iOS**) and **`FountainTests`**. Targets link the **local** **Fountain** product (see [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)); app/test host sources live outside the package tree paths above. |

### Xcode + local package (done)

See **[Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)** for verification steps, `@testable import` notes, and rollback if package wiring must be reverted.

**SPM** remains authoritative for API and CI; **library** edits are made under **`Fountain/`** and **`Package.swift`** only — Xcode picks them up through the package dependency.

## What “deprecated” means here

See **§ Phase 0.3** above for the authoritative rules. Prefer **`FountainCore`**, the default **tokenizer pipeline**, and **`FountainDocument`** for new work. **`CHANGELOG.md`** records parser removals and migration notes.

---

## Parser classification — Phase 4.6 (whitespace-only “action” lines)

**Change (Fountain 1.1 alignment):** A body line that contains **only** whitespace (two spaces, tabs, etc.) **outside** a dialogue block is **no longer** emitted as a standalone **`Action`** element. It is treated like a **blank** delimiter (same effect on slug / character rules as an empty line). **Inside** dialogue, whitespace-only lines still extend the dialogue block (including the historical **two-space** continuation rule).

**Migration:** If you relied on invisible “action” rows made only of spaces, switch to explicit forced action with **`!`** at the start of the line, or use real action text. Token-pipeline and fast parser stay aligned; see **`Phase46WhitespaceActionTests`** and roadmap **Phase 4.6**.
