# Deprecation and distribution (Phases 0.3 & 1.2)

**Version axes:** **Fountain syntax 1.1** (``FountainSyntaxPin``, JSON ``fountainSyntaxVersion``) is independent of **Swift package SemVer** (``FountainPackageVersion``, git tags, [CHANGELOG.md](../CHANGELOG.md)). A **2.0.0** library release does not imply Fountain **2.0** markup.

## Phase 1.2 — SwiftPM canonical (Phase **15.1** complete)

- **SwiftPM (`Package.swift`)** defines **FountainCore**, **FountainHTML**, and umbrella **Fountain**; CI at the repo root is authoritative.
- **Library sources** live only under **`Fountain/`** (and **`Sources/Fountain/`** for the umbrella shim). There is no forked second codebase for the Swift library.
- **`Fountain.xcodeproj`** was **removed** in **Phase 15.1**; **`FountainTests`** is a normal **`swift test`** target. **macOS** **WKWebView** sample: **`Samples/FountainSampleMac/`**. Details: [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md).

---

## Phase 0.3 — Deprecation policy (decided)

This is the **baseline policy** for the Swift next-gen roadmap. Breaking removals are listed in **[CHANGELOG.md](../CHANGELOG.md)** and tagged on **`main`** per [SPM-Release-Checklist.md](SPM-Release-Checklist.md).

| Asset | Status | Rule |
|-------|--------|------|
| **`FountainParsePipeline`** / **``.tokenPipeline``** | **Default** | **``FNScript``** sync, async, and stream entry points without an explicit **`parser:`** use the tokenizer-first pipeline (Phases **3–4**). New Fountain 1.1 behavior and parity tests target this path first. |
| **`FastFountainParser`** (**``.fast``**) | **Explicit opt-in** | Line-first engine for regression, benchmarks, or apps that still depend on its exact behavior. Not the default initializer path. |
| **Xcode vs SwiftPM** | **SPM-only (Phase 15.1)** | **CI and API truth** are **`swift build` / `swift test`** on `Package.swift` only — [Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md). |

**Removed (Phase 14.2–14.3, pre-`2.0.0` tag):** **`Fountain/Legacy/`** (Objective-C + RegexKitLite reference tree) and the Swift **`FountainParser`** pipeline / **`FNParserType.regex`**. Consumers that still need RegexKitLite-era sources must vendor them from git history.

**Feature flags:** The default `FNScript` initializers use **``.tokenPipeline``** (``FountainParsePipeline``). **`parser: .fast`** is explicit; no separate feature flag is required.

**Phase 4.6 (whitespace-only “action”):** Standalone lines that are **only** whitespace are **no longer** emitted as **Action** elements (they behave like blanks / dialogue continuations per parser rules). Consumers that relied on whitespace-only rows as visible **Action** beats should use **forced action** (`!`) per [Fountain 1.1](https://fountain.io/syntax/). Tracked under **Phase 15.2** polish.

---

## Legacy Objective-C and RegexKitLite (removed from tree)

- **`Fountain/Legacy/`** has been **deleted** from the repository. **SwiftPM** never compiled it; archived copies may exist in **git history** or forks.
- **`FountainRegexes.swift`** and **`String+Regex.swift`** remain for **HTML** export, inline markup, and related string helpers — not for a second full-document Swift parser.

## Two ways to work with the same Swift sources

| Path | Use when |
|------|----------|
| **SwiftPM** (`Package.swift`) | Libraries, CI, package-first development (`swift build`, `swift test`). **Canonical** module graph for **`FountainCore`** / **`FountainHTML`** / umbrella **`Fountain`**. |
| **Samples** | **`Samples/FountainSampleMac/`** nested package (macOS **WKWebView** demo). **iOS:** integrate **`Fountain`** into your own app target. |

### Opening in Xcode

**File → Open** the repo’s **`Package.swift`**. Use **`swift test`** for verification; see **[Phase-1-Xcode-SPM-Integration.md](Phase-1-Xcode-SPM-Integration.md)** for the **macOS** sample and **`FountainTests`** layout.

**Library** edits are made under **`Fountain/`**, **`FountainUI/`**, and **`Package.swift`** only.

## What “deprecated” means here

See **§ Phase 0.3** above for the authoritative rules. Prefer **`FountainCore`**, the default **tokenizer pipeline**, and **`FountainDocument`** for new work. **`CHANGELOG.md`** records parser removals and migration notes.

---

## Parser classification — Phase 4.6 (whitespace-only “action” lines)

**Change (Fountain 1.1 alignment):** A body line that contains **only** whitespace (two spaces, tabs, etc.) **outside** a dialogue block is **no longer** emitted as a standalone **`Action`** element. It is treated like a **blank** delimiter (same effect on slug / character rules as an empty line). **Inside** dialogue, whitespace-only lines still extend the dialogue block (including the historical **two-space** continuation rule).

**Migration:** If you relied on invisible “action” rows made only of spaces, switch to explicit forced action with **`!`** at the start of the line, or use real action text. Token-pipeline and fast parser stay aligned; see **`Phase46WhitespaceActionTests`** and roadmap **Phase 4.6**.
