//
//  FountainParsePipeline.swift
//
//  Tokenizer-first parse path (Phase 3–4): title prescan → line tokens → ``FNElement`` assembly.
//  Default for ``FNScript`` (``FNParserType/tokenPipeline``); ``FastFountainParser`` is ``FNParserType/fast``.
//

import Foundation

/// Shared entry point for the **tokenizer → elements** pipeline (architecture migration).
///
/// Uses the same title-page prescan and body tokenization as ``FountainScriptElementsBuilder/buildElements(fromRawDocument:)``,
/// but exposes ``titlePage`` and ``elements`` together so ``FNScript`` can populate both fields without duplicating logic.
public enum FountainParsePipeline: Sendable {
    /// Parses a full Fountain document string: normalized prescan, title page extraction, body tokenization, element assembly.
    public static func parseDocument(string rawDocument: String) -> (titlePage: [[String: [String]]], elements: [FNElement]) {
        let (titlePage, tokens) = FountainBodyLineTokenizer.tokenizeBodyAfterTitlePrescan(rawDocument: rawDocument)
        let elements = FountainScriptElementsBuilder.buildElements(fromBodyTokens: tokens)
        return (titlePage, elements)
    }

    /// Reads UTF-8 file contents then parses (mirrors ``FastFountainParser`` file read behavior on failure: empty script).
    public static func parseDocument(file path: String) -> (titlePage: [[String: [String]]], elements: [FNElement]) {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return ([], [])
        }
        return parseDocument(string: contents)
    }
}
