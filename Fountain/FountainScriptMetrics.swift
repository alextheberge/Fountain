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
    /// Tokens only in `Dialogue` elements (see ``FNScript/metrics`` — uses body elements excluding boneyard).
    public var dialogueWordCount: Int
    public var elementCount: Int
    public var elementCountExcludingBoneyard: Int
    /// Sluglines (`Scene Heading` elements), including forced headings (body slice; boneyard omitted).
    public var sceneHeadingCount: Int
    /// Transitions (`Transition` elements) in the body slice.
    public var transitionCount: Int
    /// Character cues (`Character` elements) in the body slice.
    public var characterCueCount: Int
    /// Dialogue elements (one block per element; multi-line dialogue may be one element) in the body slice.
    public var dialogueElementCount: Int
    /// `===` page breaks (`Page Break` elements).
    public var pageBreakCount: Int
    /// `/* … */` regions collapsed to one element each.
    public var boneyardElementCount: Int
    /// `#` / `##` / … section headings.
    public var sectionHeadingCount: Int
    /// `=` synopsis lines.
    public var synopsisCount: Int
    /// `[[ … ]]` bracket notes (`Comment` elements).
    public var commentNoteCount: Int

    public init(
        wordCountExcludingBoneyard: Int,
        dialogueWordCount: Int,
        elementCount: Int,
        elementCountExcludingBoneyard: Int,
        sceneHeadingCount: Int,
        transitionCount: Int,
        characterCueCount: Int,
        dialogueElementCount: Int,
        pageBreakCount: Int = 0,
        boneyardElementCount: Int = 0,
        sectionHeadingCount: Int = 0,
        synopsisCount: Int = 0,
        commentNoteCount: Int = 0
    ) {
        self.wordCountExcludingBoneyard = wordCountExcludingBoneyard
        self.dialogueWordCount = dialogueWordCount
        self.elementCount = elementCount
        self.elementCountExcludingBoneyard = elementCountExcludingBoneyard
        self.sceneHeadingCount = sceneHeadingCount
        self.transitionCount = transitionCount
        self.characterCueCount = characterCueCount
        self.dialogueElementCount = dialogueElementCount
        self.pageBreakCount = pageBreakCount
        self.boneyardElementCount = boneyardElementCount
        self.sectionHeadingCount = sectionHeadingCount
        self.synopsisCount = synopsisCount
        self.commentNoteCount = commentNoteCount
    }
}

extension FNScript {
    /// Word and element counts for analytics. Body-wide word counts use ``elementsExcludingBoneyard``; dialogue tokens use dialogue elements from that same slice so boneyard never contributes (Phase 5.3).
    public var metrics: FountainScriptMetrics {
        let body = elementsExcludingBoneyard
        let wordCount = tokenCount(in: body.map(\.elementText).joined(separator: "\n"))
        let dialoguePieces = body.filter { $0.elementType == FNElementType.dialogue.rawValue }
        let dialogueWords = tokenCount(in: dialoguePieces.map(\.elementText).joined(separator: "\n"))
        let scenes = body.filter { $0.elementType == FNElementType.sceneHeading.rawValue }.count
        let transitions = body.filter { $0.elementType == FNElementType.transition.rawValue }.count
        let characterCues = body.filter { $0.elementType == FNElementType.character.rawValue }.count
        let dialogueElements = body.filter { $0.elementType == FNElementType.dialogue.rawValue }.count
        let pageBreaks = body.filter { $0.elementType == FNElementType.pageBreak.rawValue }.count
        let boneyards = elements.filter { $0.elementType == FNElementType.boneyard.rawValue }.count
        let sections = body.filter { $0.elementType == FNElementType.sectionHeading.rawValue }.count
        let synopses = body.filter { $0.elementType == FNElementType.synopsis.rawValue }.count
        let notes = body.filter { $0.elementType == FNElementType.comment.rawValue }.count
        return FountainScriptMetrics(
            wordCountExcludingBoneyard: wordCount,
            dialogueWordCount: dialogueWords,
            elementCount: elements.count,
            elementCountExcludingBoneyard: body.count,
            sceneHeadingCount: scenes,
            transitionCount: transitions,
            characterCueCount: characterCues,
            dialogueElementCount: dialogueElements,
            pageBreakCount: pageBreaks,
            boneyardElementCount: boneyards,
            sectionHeadingCount: sections,
            synopsisCount: synopses,
            commentNoteCount: notes
        )
    }

    private func tokenCount(in text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }
}
