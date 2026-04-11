//
//  FNScript.swift
//
//  Copyright (c) 2012-2013 Nima Yousefi & John August
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

/// Parser backend for ``FNScript`` initializers, ``loadString`` / ``loadFile``, async parse, streaming, and incremental parse.
public enum FNParserType: Sendable, Equatable {
    /// **Line-first** parser (``FastFountainParser``). Explicit opt-in for parity tests or migration from pre–Phase 12 defaults.
    case fast
    /// Legacy **regex** pipeline (``FountainParser``).
    case regex
    /// **Tokenizer-first** canonical path: ``FountainTitlePagePrescan`` + ``FountainBodyLineTokenizer`` + ``FountainScriptElementsBuilder`` (Phases 3–4). **Default** for ``init(string:)`` / ``init(file:)`` and async/stream entry points (Phase 12).
    case tokenPipeline
}

/// Loaded Fountain screenplay: title page, body elements, and export helpers.
///
/// By default ``init(string:)`` and ``init(file:)`` use ``FountainParsePipeline`` (``FNParserType/tokenPipeline``) and run **synchronously** on the caller’s thread.
/// Use ``init(string:parser:)`` with ``FNParserType/fast`` or ``FNParserType/regex`` only when you need those engines explicitly (parity, migration, or legacy apps).
/// For **large** screenplays—or any full parse from the main thread—prefer ``parseStringAsync(_:)`` / ``parseFileAsync(_:)``
/// (Phase 9.1: parse work runs in a detached task). Overloads with **`parser:`** default to **`.tokenPipeline`**; pass **`.fast`** or **`.regex`** when required. Use ``asFountainDocument()`` for JSON/tooling via `FountainDocument`.
/// After edits, ``parseIncremental(newText:editedUTF16Range:parser:)`` (Phase 9.5) performs a **full** re-parse while preserving matching prefix/suffix ``FNElement/id`` values and returning an expanded invalidation UTF-16 span (see ``FountainEditRangeExpansion``).
public class FNScript: CustomStringConvertible {
    public var filename: String?
    public var elements: [FNElement] = []
    public var titlePage: [[String: [String]]] = []
    public var suppressSceneNumbers: Bool = false

    public init() {}

    public init(file path: String) {
        loadFile(path)
    }

    public init(string: String) {
        loadString(string)
    }

    public func loadFile(_ path: String) {
        loadFile(path, parser: .tokenPipeline)
    }

    public func loadString(_ string: String) {
        loadString(string, parser: .tokenPipeline)
    }

    public func stringFromDocument() -> String {
        return FountainWriter.documentFromScript(self)
    }

    public func stringFromTitlePage() -> String {
        return FountainWriter.titlePageFromScript(self)
    }

    public func stringFromBody() -> String {
        return FountainWriter.bodyFromScript(self)
    }

    @discardableResult
    public func writeToFile(_ path: String) -> Bool {
        let document = FountainWriter.documentFromScript(self)
        do {
            try document.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public func writeToURL(_ url: URL) -> Bool {
        let document = FountainWriter.documentFromScript(self)
        do {
            try document.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    public var description: String {
        return FountainWriter.documentFromScript(self)
    }

    // MARK: - Parser selection (`FNParserType`)
    // Default ``loadString`` / ``loadFile`` use ``FNParserType/tokenPipeline`` (Phase 12).

    public init(file path: String, parser parserType: FNParserType) {
        loadFile(path, parser: parserType)
    }

    public init(string: String, parser parserType: FNParserType) {
        loadString(string, parser: parserType)
    }

    public func loadFile(_ path: String, parser parserType: FNParserType) {
        filename = (path as NSString).lastPathComponent
        switch parserType {
        case .regex:
            elements = FountainParser.parseBody(ofFile: path)
            titlePage = FountainParser.parseTitlePage(ofFile: path)
        case .tokenPipeline:
            let parsed = FountainParsePipeline.parseDocument(file: path)
            elements = parsed.elements
            titlePage = parsed.titlePage
        case .fast:
            let parser = FastFountainParser(file: path)
            elements = parser.elements
            titlePage = parser.titlePage
        }
    }

    public func loadString(_ string: String, parser parserType: FNParserType) {
        filename = nil
        switch parserType {
        case .regex:
            elements = FountainParser.parseBody(ofString: string)
            titlePage = FountainParser.parseTitlePage(ofString: string)
        case .tokenPipeline:
            let parsed = FountainParsePipeline.parseDocument(string: string)
            elements = parsed.elements
            titlePage = parsed.titlePage
        case .fast:
            let parser = FastFountainParser(string: string)
            elements = parser.elements
            titlePage = parser.titlePage
        }
    }
}

extension FNScript {
    /// Body elements excluding boneyard (`/* … */`) regions — for word-count, timing, or dialogue metrics (Phase 5.3).
    public var elementsExcludingBoneyard: [FNElement] {
        elements.filter { $0.elementType != FNElementType.boneyard.rawValue }
    }

    /// Codable snapshot for JSON / tooling (Phase 2.4). Same content as ``asFountainDocument()``; ``ScriptElement/id`` matches each parsed ``FNElement/id``.
    public var fountainDocument: FountainDocument {
        asFountainDocument()
    }

    /// Encodes a single ``asFountainDocument()`` snapshot as JSON (UTF-8). Uses one parse snapshot so element IDs match a decode round-trip.
    public func fountainDocumentJSONData(prettyPrinted: Bool = false) throws -> Data {
        let document = asFountainDocument()
        let enc = JSONEncoder()
        if prettyPrinted {
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        return try enc.encode(document)
    }
}

// MARK: - Phase 9.1 (async parse)

extension FNScript {
    /// Parses on a detached task so callers can `await` without blocking the caller’s executor.
    /// Prefer synchronous ``init(string:)`` only for small snippets or when the caller is already on a background executor.
    public static func parseStringAsync(_ string: String) async -> FNScript {
        await parseStringAsync(string, parser: .tokenPipeline)
    }

    /// Async parse with an explicit parser engine (e.g. ``FNParserType/tokenPipeline`` for migration testing).
    public static func parseStringAsync(_ string: String, parser: FNParserType) async -> FNScript {
        await Task.detached {
            FNScript(string: string, parser: parser)
        }.value
    }

    /// Async variant of ``init(file:)`` using the default tokenizer pipeline; work runs in a detached task (Phase 9.1).
    public static func parseFileAsync(_ path: String) async -> FNScript {
        await parseFileAsync(path, parser: .tokenPipeline)
    }

    /// Async file parse with an explicit parser engine.
    public static func parseFileAsync(_ path: String, parser: FNParserType) async -> FNScript {
        await Task.detached {
            FNScript(file: path, parser: parser)
        }.value
    }

    // MARK: - Phase 9.2 (streaming / preview)

    /// Async stream of ``ScriptElement`` after a **full** parse (handy for UI previews; not incremental).
    /// Uses ``parseStringAsync(_:)`` so the heavy parse does not run synchronously on the caller.
    public static func scriptElementStream(from string: String) -> AsyncStream<ScriptElement> {
        scriptElementStream(from: string, parser: .tokenPipeline)
    }

    /// Like ``scriptElementStream(from:)``, but selects the parser engine (e.g. ``FNParserType/tokenPipeline``).
    public static func scriptElementStream(from string: String, parser: FNParserType) -> AsyncStream<ScriptElement> {
        AsyncStream { continuation in
            Task {
                let script = await parseStringAsync(string, parser: parser)
                let doc = FountainDocument(script: script)
                for el in doc.elements {
                    continuation.yield(el)
                }
                continuation.finish()
            }
        }
    }

    /// Like ``scriptElementStream(from:)``, but reads the screenplay from disk (uses ``parseFileAsync`` + one ``FountainDocument`` snapshot).
    public static func scriptElementStream(fromFile path: String) -> AsyncStream<ScriptElement> {
        scriptElementStream(fromFile: path, parser: .tokenPipeline)
    }

    /// File-backed stream with an explicit parser engine.
    public static func scriptElementStream(fromFile path: String, parser: FNParserType) -> AsyncStream<ScriptElement> {
        AsyncStream { continuation in
            Task {
                let script = await parseFileAsync(path, parser: parser)
                let doc = FountainDocument(script: script)
                for el in doc.elements {
                    continuation.yield(el)
                }
                continuation.finish()
            }
        }
    }
}
