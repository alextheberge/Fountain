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

/// Which parser implementation ``FNScript`` uses when you opt into the regex pipeline.
public enum FNParserType {
    case fast
    case regex
}

/// Loaded Fountain screenplay: title page, body elements, and export helpers.
///
/// By default ``init(string:)`` and ``init(file:)`` use ``FastFountainParser`` and run **synchronously** on the caller’s thread.
/// That is appropriate for **small** documents, unit tests, and tooling that already runs off the main thread.
/// For **large** screenplays—or any full parse from the main thread—prefer ``parseStringAsync(_:)`` / ``parseFileAsync(_:)``
/// (Phase 9.1: parse work runs in a detached task). Use ``asFountainDocument()`` for JSON/tooling via `FountainDocument`.
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
        filename = (path as NSString).lastPathComponent
        let parser = FastFountainParser(file: path)
        elements = parser.elements
        titlePage = parser.titlePage
    }

    public func loadString(_ string: String) {
        filename = nil
        let parser = FastFountainParser(string: string)
        elements = parser.elements
        titlePage = parser.titlePage
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

    // MARK: - Legacy parser methods
    // These methods exist for backwards compatibility. Prefer the default (fast) parser.

    public init(file path: String, parser parserType: FNParserType) {
        loadFile(path, parser: parserType)
    }

    public init(string: String, parser parserType: FNParserType) {
        loadString(string, parser: parserType)
    }

    public func loadFile(_ path: String, parser parserType: FNParserType) {
        filename = (path as NSString).lastPathComponent
        if parserType == .regex {
            elements = FountainParser.parseBody(ofFile: path)
            titlePage = FountainParser.parseTitlePage(ofFile: path)
        } else {
            let parser = FastFountainParser(file: path)
            elements = parser.elements
            titlePage = parser.titlePage
        }
    }

    public func loadString(_ string: String, parser parserType: FNParserType) {
        filename = nil
        if parserType == .regex {
            elements = FountainParser.parseBody(ofString: string)
            titlePage = FountainParser.parseTitlePage(ofString: string)
        } else {
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
        await Task.detached {
            FNScript(string: string)
        }.value
    }

    /// Async variant of ``init(file:)`` using the default fast parser; work runs in a detached task (Phase 9.1).
    public static func parseFileAsync(_ path: String) async -> FNScript {
        await Task.detached {
            FNScript(file: path)
        }.value
    }

    // MARK: - Phase 9.2 (streaming / preview)

    /// Async stream of ``ScriptElement`` after a **full** parse (handy for UI previews; not incremental).
    /// Uses ``parseStringAsync(_:)`` so the heavy parse does not run synchronously on the caller.
    public static func scriptElementStream(from string: String) -> AsyncStream<ScriptElement> {
        AsyncStream { continuation in
            Task {
                let script = await parseStringAsync(string)
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
        AsyncStream { continuation in
            Task {
                let script = await parseFileAsync(path)
                let doc = FountainDocument(script: script)
                for el in doc.elements {
                    continuation.yield(el)
                }
                continuation.finish()
            }
        }
    }
}
