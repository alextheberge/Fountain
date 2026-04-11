//
//  FountainScriptMetrics.swift
//
//  Phase 5.3 — lightweight estimators for dialogue / word counts (boneyard excluded where noted).
//

import Foundation

/// Derived statistics from a parsed ``FNScript`` (timing, word-count UI, coverage dashboards).
public struct FountainScriptMetrics: Sendable, Equatable {
    /// Whitespace-separated tokens across all ``elementsExcludingBoneyard`` element texts.
    public var wordCountExcludingBoneyard: Int
    /// Tokens only in `Dialogue` elements (boneyard dialogue is already excluded from elements when filtered).
    public var dialogueWordCount: Int
    public var elementCount: Int
    public var elementCountExcludingBoneyard: Int
    /// Sluglines (`Scene Heading` elements), including forced headings.
    public var sceneHeadingCount: Int
    /// Transitions (`Transition` elements).
    public var transitionCount: Int
    /// Character cues (`Character` elements).
    public var characterCueCount: Int
    /// Dialogue elements (one block per element; multi-line dialogue may be one element).
    public var dialogueElementCount: Int

    public init(
        wordCountExcludingBoneyard: Int,
        dialogueWordCount: Int,
        elementCount: Int,
        elementCountExcludingBoneyard: Int,
        sceneHeadingCount: Int,
        transitionCount: Int,
        characterCueCount: Int,
        dialogueElementCount: Int
    ) {
        self.wordCountExcludingBoneyard = wordCountExcludingBoneyard
        self.dialogueWordCount = dialogueWordCount
        self.elementCount = elementCount
        self.elementCountExcludingBoneyard = elementCountExcludingBoneyard
        self.sceneHeadingCount = sceneHeadingCount
        self.transitionCount = transitionCount
        self.characterCueCount = characterCueCount
        self.dialogueElementCount = dialogueElementCount
    }
}

extension FNScript {
    /// Word and element counts for analytics. Dialogue words use only `Dialogue`-typed elements; boneyard is omitted from body-wide counts via ``elementsExcludingBoneyard``.
    public var metrics: FountainScriptMetrics {
        let body = elementsExcludingBoneyard
        let wordCount = tokenCount(in: body.map(\.elementText).joined(separator: "\n"))
        let dialoguePieces = elements.filter { $0.elementType == FNElementType.dialogue.rawValue }
        let dialogueWords = tokenCount(in: dialoguePieces.map(\.elementText).joined(separator: "\n"))
        let scenes = elements.filter { $0.elementType == FNElementType.sceneHeading.rawValue }.count
        let transitions = elements.filter { $0.elementType == FNElementType.transition.rawValue }.count
        let characterCues = elements.filter { $0.elementType == FNElementType.character.rawValue }.count
        let dialogueElements = elements.filter { $0.elementType == FNElementType.dialogue.rawValue }.count
        return FountainScriptMetrics(
            wordCountExcludingBoneyard: wordCount,
            dialogueWordCount: dialogueWords,
            elementCount: elements.count,
            elementCountExcludingBoneyard: body.count,
            sceneHeadingCount: scenes,
            transitionCount: transitions,
            characterCueCount: characterCues,
            dialogueElementCount: dialogueElements
        )
    }

    private func tokenCount(in text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }
}
