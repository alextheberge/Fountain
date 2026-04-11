//
//  FountainCodable.swift
//
//  Next-gen interchange model (Phase 2). Maps parsed ``FNElement`` values to
//  ``ScriptElement`` / ``FountainDocument`` for JSON and tooling.
//

import Foundation

/// Keys used in ``ScriptElement.metadata`` when mapping from ``FNElement`` (Phase 2.2).
public enum FountainMetadataKey: String, Sendable {
    case sceneNumber
    case centered
    case dualDialogue
    /// `0` = left column, `1` = right column (Fountain `^` cue).
    case dualDialogueColumn
    case sectionDepth
}

/// Stable element kinds for export and AI/tooling pipelines (Fountain 1.1–aligned naming).
public enum ScriptElementKind: String, Codable, CaseIterable, Sendable {
    case sceneHeading
    case action
    case character
    case dialogue
    case parenthetical
    case transition
    case lyrics
    case sectionHeading
    case synopsis
    case pageBreak
    case boneyard
    case comment
    case general
    case unknown
}

/// One structural element in a parsed screenplay.
public struct ScriptElement: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var kind: ScriptElementKind
    public var text: String
    /// Scene numbers, section depth, dual-dialogue, centered, etc.
    public var metadata: [String: String]

    public init(id: UUID = UUID(), kind: ScriptElementKind, text: String, metadata: [String: String] = [:]) {
        self.id = id
        self.kind = kind
        self.text = text
        self.metadata = metadata
    }
}

/// Serializable document: title page + body elements + format hint.
public struct FountainDocument: Codable, Sendable, Equatable {
    public var titlePage: [[String: [String]]]
    public var elements: [ScriptElement]
    /// Target syntax level for downstream tools (not validated here).
    public var fountainSyntaxVersion: String

    public init(
        titlePage: [[String: [String]]] = [],
        elements: [ScriptElement] = [],
        fountainSyntaxVersion: String = FountainSyntaxPin.targetVersionLabel
    ) {
        self.titlePage = titlePage
        self.elements = elements
        self.fountainSyntaxVersion = fountainSyntaxVersion
    }

    /// Interchange snapshot from a parsed screenplay (Phase 2.4 — prefer this for JSON / writers).
    public init(script: FNScript, fountainSyntaxVersion: String = FountainSyntaxPin.targetVersionLabel) {
        self = script.asFountainDocument(fountainSyntaxVersion: fountainSyntaxVersion)
    }
}

extension FNScript {
    /// Snapshot of this script as a `Codable` document (for JSON, LLM context, etc.).
    public func asFountainDocument(fountainSyntaxVersion: String = FountainSyntaxPin.targetVersionLabel) -> FountainDocument {
        let mapped = elements.map { $0.asScriptElement() }
        return FountainDocument(titlePage: titlePage, elements: mapped, fountainSyntaxVersion: fountainSyntaxVersion)
    }
}

extension FNElement {
    fileprivate func asScriptElement() -> ScriptElement {
        var meta: [String: String] = [:]
        if let sn = sceneNumber { meta[FountainMetadataKey.sceneNumber.rawValue] = sn }
        if isCentered { meta[FountainMetadataKey.centered.rawValue] = "true" }
        if isDualDialogue { meta[FountainMetadataKey.dualDialogue.rawValue] = "true" }
        if let col = dualDialogueColumn { meta[FountainMetadataKey.dualDialogueColumn.rawValue] = String(col) }
        if sectionDepth > 0 { meta[FountainMetadataKey.sectionDepth.rawValue] = String(sectionDepth) }
        return ScriptElement(id: id, kind: ScriptElementKind(legacyType: elementType), text: elementText, metadata: meta)
    }
}

extension ScriptElementKind {
    /// Maps legacy `FNElement.elementType` strings; unknown labels become ``unknown``.
    public init(legacyType: String) {
        if let t = FNElementType(rawValue: legacyType) {
            self = t.scriptElementKind
        } else {
            self = .unknown
        }
    }
}
