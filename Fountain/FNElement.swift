//
//  FNElement.swift
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

/// One structural unit in a parsed screenplay (value type; Phase 2).
///
/// The fast parser sets ``elementType`` to English labels matching ``FNElementType``.
/// Each element has a stable ``id`` that is carried into ``ScriptElement`` via
/// ``FNScript/asFountainDocument()`` for JSON round-trips. Prefer that path for
/// `Codable` interchange; ``FNElement`` itself is also `Codable` for diagnostics
/// or local persistence.
public struct FNElement: Codable, Identifiable, Sendable, CustomStringConvertible {
    public var id: UUID
    public var elementType: String
    public var elementText: String
    public var isCentered: Bool

    // Type-specific properties
    public var sceneNumber: String?
    public var isDualDialogue: Bool
    /// When ``isDualDialogue`` is true: `0` = left column (first cue), `1` = right column (cue with trailing `^`).
    public var dualDialogueColumn: Int?
    public var sectionDepth: Int

    public init(
        id: UUID = UUID(),
        elementType: String = "",
        elementText: String = "",
        isCentered: Bool = false,
        sceneNumber: String? = nil,
        isDualDialogue: Bool = false,
        dualDialogueColumn: Int? = nil,
        sectionDepth: Int = 0
    ) {
        self.id = id
        self.elementType = elementType
        self.elementText = elementText
        self.isCentered = isCentered
        self.sceneNumber = sceneNumber
        self.isDualDialogue = isDualDialogue
        self.dualDialogueColumn = dualDialogueColumn
        self.sectionDepth = sectionDepth
    }

    public static func element(ofType type: String, text: String) -> FNElement {
        FNElement(id: UUID(), elementType: type, elementText: text)
    }

    public var description: String {
        var typeOutput = elementType
        if isCentered {
            typeOutput += " (centered)"
        } else if isDualDialogue {
            typeOutput += " (dual dialogue)"
        } else if sectionDepth > 0 {
            typeOutput += " (\(sectionDepth)d)"
        }
        return "\(typeOutput): \(elementText)"
    }
}
