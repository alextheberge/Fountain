# SwiftWasm (Phase 10.3 — experimental)

**Goal:** Cross-compile **`FountainCore`** (parser + model + plain writers) for **WebAssembly** so Fountain tooling can run in the browser without a native binary.

## Current reality

- `Package.swift` declares **Apple** platforms (**macOS 13+**, **iOS 16+** — Phase **11** Swift `Regex` floor). Cross-compiling with a **Swift SDK for Wasm** is still the supported experiment path; there is no `SupportedPlatform.wasi` entry in this manifest yet.
- **`FountainHTML`** depends on **UIKit/AppKit** (`Platform.swift`, `FNHTMLScript`, `FNPaginator`) and is **not** Wasm-viable as-is — exclude from Wasm builds (same split as today’s `FountainCore` / `FountainHTML` targets).
- **`FountainCore`** uses **Foundation** (file paths in `FNScript.init(file:)`, etc.). **`String+Regex.swift`** (Phase **11**) uses Swift **`Regex`** first and falls back to **`NSRegularExpression`** only when Swift rejects a pattern (e.g. negative lookbehind in ``ITALIC_PATTERN``). **`FountainRegexes`** body-parser patterns avoid lookbehind so they stay on the Swift path. A Wasm deployment should still treat **file URL** entry points as unsupported or bridge from JS (see below). **PDF:** ``FountainPDFWriter`` is a stub when **CoreGraphics / CoreText** are unavailable (including **wasm32**); use ``FountainFDXWriter`` / plaintext / JSON — see [ADR-008-PDF-CoreGraphics-availability.md](ADR-008-PDF-CoreGraphics-availability.md).

## Build script (local or CI)

- **`scripts/build-fountaincore-wasm.sh`** — runs `swift build --target FountainCore --swift-sdk "$SWIFT_SDK_ID"`.
- Set **`SWIFT_SDK_ID`** to the SDK id from `swift sdk list` or from the **`swift-sdk-id`** output of [`swiftwasm/setup-swiftwasm`](https://github.com/swiftwasm/setup-swiftwasm) (used in CI).

## CI (manual)

Wasm is **not** run on every push (toolchain + SDK size); it is available as a **manual** workflow:

- [`.github/workflows/fountaincore-wasm.yml`](../.github/workflows/fountaincore-wasm.yml) — **Actions → “Wasm: FountainCore” → Run workflow** on `master` / your branch.

Uses **`swift:6.0.3-noble`** + **`swiftwasm/setup-swiftwasm@v2`** + the script above. If the job fails after a Swift or SDK upgrade, update this doc and the workflow container/SDK pin.

## Unsupported / risky on Wasm

| API / pattern | Notes |
|---------------|--------|
| **`FNScript(file:)`** / **`parseFileAsync(_:)`** reading host paths | No traditional POSIX filesystem in the browser; pass **`String`** / async string from JS host. |
| **`FountainHTML`** (`FNHTMLScript`, `FNPaginator`, `Platform`) | UIKit/AppKit — **omit** from Wasm products. |
| **``FNPaginator`` / ``FountainTextMeasuring``** | On a **native** host that compiles **FountainHTML**, prefer ``init(script:textMeasurer:)`` with ``CourierPitchMonospaceTextMeasurer`` or ``AppKitFountainTextMeasurer``. For a **hypothetical** Wasm+HTML port, you would supply ``init(script:layoutLineHeight:measureHeight:)`` with a closure implemented in JS (e.g. Canvas **measureText**) or a fixed pitch model — not shipped in-repo. |
| **Paginated PDF** (`FountainPDFPagination`) | Umbrella **Fountain** only; needs **FountainHTML** + CoreGraphics — **omit** on Wasm; see [ADR-008-PDF-CoreGraphics-availability.md](ADR-008-PDF-CoreGraphics-availability.md). |
| **`NSRegularExpression` / `NSString` regex bridging** | **Mostly removed** from **`String+Regex.swift`** (Phase **11**): Swift **`Regex`** first; tiny **`NSRegularExpression`** fallback only when Swift cannot compile a pattern (e.g. lookbehind). Other Foundation APIs may still bridge `NSString` where unavoidable. |
| **`Task.detached`** (Phase 9.1 async parse) | Verify against your SwiftWasm concurrency/runtime version; prefer cooperative tasks if issues appear. |
| **Full `swift test` on Wasm** | Not in CI yet; tests assume Apple test bundles and fixtures. |

## Parser / UI boundary (Phase 10.2)

Core sources under `Fountain/*.swift` **must not** use `canImport(UIKit|AppKit)` or `import UIKit` / `import AppKit` except in **`Platform.swift`**, **`FNPaginator.swift`**, **`FNHTMLScript.swift`**, and **`AppKitFountainTextMeasurer.swift`** (compiled only as **FountainHTML**). This is enforced in **`.github/workflows/swift.yml`** on every push/PR.

## CoreGraphics / CoreText boundary (Phase 10.4)

**FountainCore** must remain buildable for **wasm32** (stub) and any future host **without** linking Apple graphics stacks from random sources.

- The **only** `Fountain/*.swift` file that may use `import CoreGraphics`, `import CoreText`, or `canImport(CoreGraphics|CoreText)` is **`FountainPDFWriter.swift`**, which already gates the real PDF implementation and throws ``FountainStubRendererError`` on Wasm or when CG/CT are unavailable — see [ADR-008-PDF-CoreGraphics-availability.md](ADR-008-PDF-CoreGraphics-availability.md).
- **`.github/workflows/swift.yml`** runs a second grep (after Phase 10.2) so new Core-only sources cannot accidentally pull CG/CT. If you split PDF into another file, extend that workflow allowlist **and** this section together.

## Status

**Manual CI + script in tree** — run the **Wasm: FountainCore** workflow after substantive parser changes. Update this file when a Wasm SDK pin or Foundation limitation changes.
