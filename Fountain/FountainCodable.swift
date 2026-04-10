//
//  FountainCodable.swift
//
//  Next-gen interchange model (Phase 2 starter). Maps the legacy FNElement graph to
//  Codable structs for JSON and tooling. The runtime parser still uses FNElement.
//

import Foundation

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
        fountainSyntaxVersion: String = "1.1"
    ) {
        self.titlePage = titlePage
        self.elements = elements
        self.fountainSyntaxVersion = fountainSyntaxVersion
    }
}

extension FNScript {
    /// Snapshot of this script as a `Codable` document (for JSON, LLM context, etc.).
    public func asFountainDocument(fountainSyntaxVersion: String = "1.1") -> FountainDocument {
        let mapped = elements.map { $0.asScriptElement() }
        return FountainDocument(titlePage: titlePage, elements: mapped, fountainSyntaxVersion: fountainSyntaxVersion)
    }
}

extension FNElement {
    fileprivate func asScriptElement() -> ScriptElement {
        var meta: [String: String] = [:]
        if let sn = sceneNumber { meta["sceneNumber"] = sn }
        if isCentered { meta["centered"] = "true" }
        if isDualDialogue { meta["dualDialogue"] = "true" }
        if sectionDepth > 0 { meta["sectionDepth"] = String(sectionDepth) }
        return ScriptElement(kind: ScriptElementKind(legacyType: elementType), text: elementText, metadata: meta)
    }
}

extension ScriptElementKind {
    init(legacyType: String) {
        switch legacyType {
        case "Scene Heading": self = .sceneHeading
        case "Action": self = .action
        case "Character": self = .character
        case "Dialogue": self = .dialogue
        case "Parenthetical": self = .parenthetical
        case "Transition": self = .transition
        case "Lyrics": self = .lyrics
        case "Section Heading": self = .sectionHeading
        case "Synopsis": self = .synopsis
        case "Page Break": self = .pageBreak
        case "Boneyard": self = .boneyard
        case "Comment": self = .comment
        case "General": self = .general
        default: self = .unknown
        }
    }
}
