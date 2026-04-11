# ADR 008 — `FountainPDFWriter` and CoreGraphics / CoreText availability

**Status:** Accepted  
**Date:** 2026-04  
**Context:** Roadmap Phase **8.6** (PDF portability) and existing **Wasm** stub behavior.

## Decision

- **Real PDF** (US Letter, Courier, CoreGraphics + CoreText) compiles only when **`#if !arch(wasm32)`** and **`canImport(CoreGraphics)`** and **`canImport(CoreText)`** are all satisfied.
- Otherwise **`FountainPDFWriter`** is a **stub** that throws **`FountainStubRendererError`** with a clear message — same surface as the Wasm build.
- The package’s declared platforms remain **macOS** and **iOS**; there is **no** Linux library product today. If a future **Linux** `FountainCore` product is added without Apple graphics frameworks, this stub path is the supported behavior until a second PDF backend (e.g. pure-Swift PDF) is adopted under a separate ADR.

## Consequences

- Consumers on **Wasm** or hypothetical hosts **without** CG/CT use **FDX**, plaintext, JSON, or HTML — not PDF.
- **Paginated** PDF (**`renderPDFDataPaginated`**) lives in the umbrella **`Fountain`** target (`Sources/Fountain/FountainPDFPagination.swift`) because it requires **`FNPaginator`** from **FountainHTML** plus **`FountainPDFWriter`** from **FountainCore**.

## Alternatives considered

- **Move all PDF into FountainHTML** — would remove PDF from **`import FountainCore`** on Apple, a breaking API move for **`FountainCore`**-only apps.
- **Second PDF implementation for Linux** — deferred until a product requirement and maintainer capacity exist.
