Project Specification: Fountain Swift (Next-Gen)

1. Core Objectives

Zero Dependencies: Eliminate RegexKitLite and -licucore in favor of Swift native Regex (Swift 5.7+).

Platform Agnostic: Pure Swift implementation. Decouple core logic from Foundation, UIKit, and AppKit.

Strict Spec Compliance: Full support for Fountain 1.1, including forced elements and production features.

AI-Friendly Architecture: Use a structured data model that allows AI coding assistants to easily manipulate, query, and generate script elements.

2. Parsing Architecture (The "Universal Parser")

2.1 Implementation Strategy

Move away from a purely line-by-line regex replacement strategy to a State-Aware Scanner.

Phase 1: Tokenization: Scan the raw text to identify line types (Slugs, Action, Character, Dialogue, Parenthetical).

Phase 2: Contextual Analysis: Group tokens into logical blocks (e.g., a Dialogue Block consists of Character + Parenthetical? + Dialogue).

Phase 3: Production Feature Injection: Identify Page Breaks, Omissions, and Scene Numbers.

2.2 Standard Element Support (Fountain 1.1)

Scene Headings: Support standard prefixes (INT., EXT.) and forced headings (.).

Action: Support forced action lines (!).

Character & Dialogue: Support forced characters (@), mixed-case extensions, and Dual Dialogue (^).

Lyrics: Support forced lyrics (~).

Transitions: Support standard TO: and forced transitions (>).

Sections & Synopses: Handle hierarchical navigation (#, ##) and descriptive summaries (=).

3. The Data Model (FNElement)

The model must be a Codable Swift Struct to facilitate JSON export/import for cross-app compatibility.

public enum FNElementType: String, Codable {
    case sceneHeading, action, character, dialogue, parenthetical, transition, lyrics, section, synopsis, pageBreak, boneyard
}

public struct FNElement: Codable, Identifiable {
    public let id: UUID
    public var type: FNElementType
    public var content: String
    public var attributes: [String: String]? // For scene numbers, section depth, dual dialogue flag
}


4. Modern Rendering (The "Writer" Protocol)

Eliminate hardcoded HTML generation. Implement a protocol-based output system.

protocol FountainWriter {
    func write(script: FNScript) -> String
}

// Implementations:
// - HTMLWriter (using modern CSS Grid/Flexbox)
// - FDXWriter (Final Draft XML)
// - PDFWriter (Canvas-based rendering)
// - MarkdownWriter (Standard Markdown conversion)


5. Performance and Concurrency

Async/Await: All parsing operations must be async to prevent UI blocking on large documents (e.g., 120-page scripts).

Incremental Parsing: (Optional Advanced Feature) Ability to re-parse only affected lines during live editing.

6. Development Pain Points to Resolve

Invisible Logic: Remove reliance on trailing spaces for "forced action" (Fountain 1.0 style). Enforce the Fountain 1.1 ! prefix.

Markup Leakage: Inline styling (bold, italic, underline) must be optionally parsed into AttributedString rather than just being left as raw **text**.

Cross-App Consistency: Implement the standardized Fountain Test Suite.

Boneyard Handling: Ensure /* comments */ are correctly ignored in dialogue count and timing estimations.

7. Cross-Platform Strategy

Swift Package Manager: The primary distribution method.

Conditional Compilation: Use #if canImport(UIKit) or #if os(macOS) only for the final rendering layer, never in the parser.

Wasm Support: Ensure the library compiles with SwiftWasm for browser-based tool integration.

---

**Actionable roadmap:** For phased tasks, acceptance criteria, spec traceability, and maintenance practices, see [docs/Fountain-1.1-Implementation-Roadmap.md](docs/Fountain-1.1-Implementation-Roadmap.md).