//
//  FNPaginator.swift
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

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if SWIFT_PACKAGE
import FountainCore
#endif

public class FNPaginator {
    private let script: FNScript
    private var pages: [[FNElement]] = []

    public var numberOfPages: Int {
        if pages.isEmpty { paginate() }
        return pages.count
    }

    public init(script aScript: FNScript) {
        script = aScript
    }

    /// Paginate for US Letter paper size (8.5" × 11").
    public func paginate() {
        paginateForSize(CGSize(width: 612, height: 792))
    }

    public func pageAtIndex(_ index: Int) -> [FNElement] {
        if pages.isEmpty { paginate() }
        guard !pages.isEmpty && index <= pages.count - 1 else { return [] }
        return pages[index]
    }

    public func paginateForSize(_ pageSize: CGSize) {
        let oneInchBuffer: CGFloat = 72
        let maxPageHeight = pageSize.height - (oneInchBuffer * 2.01).rounded()

        let font = PlatformFont(name: "Courier", size: 12)!
        let lineHeight = Int(font.pointSize)

        var blockHeight = 0
        let initialY = 0
        var currentY = initialY
        var currentPage: [FNElement] = []
        var tmpElements: [FNElement] = []
        let maxElements = script.elements.count

        var previousDualDialogueBlockHeight = -1

        var i = 0
        while i < maxElements {
            defer { i += 1 }

            let element = script.elements[i]

            // Page breaks flush the current buffer and start a new page
            if element.elementType == "Page Break" {
                currentPage.append(contentsOf: tmpElements)
                tmpElements = []
                currentPage.append(element)
                pages.append(currentPage)
                currentPage = []
                currentY = initialY
                continue
            }

            let spaceBefore   = FNPaginator.spaceBeforeForElement(element) * lineHeight
            let elementWidth  = FNPaginator.widthForElement(element)
            let height        = FNPaginator.heightForString(element.elementText, font: font, maxWidth: elementWidth, lineHeight: lineHeight)

            guard height > 0 else { continue }

            blockHeight += height
            if !currentPage.isEmpty {
                blockHeight += spaceBefore
            }

            // Scene Heading: peek at the next element to avoid orphaned headings
            if element.elementType == "Scene Heading" && i + 1 < maxElements {
                let nextElement       = script.elements[i + 1]
                let nextElementWidth  = FNPaginator.widthForElement(nextElement)
                let nextElementHeight = FNPaginator.heightForString(nextElement.elementText, font: font, maxWidth: nextElementWidth, lineHeight: lineHeight)

                if (CGFloat(blockHeight + currentY + nextElementHeight) >= maxPageHeight) && nextElementHeight >= lineHeight {
                    let forcedBreak = FNElement()
                    forcedBreak.elementType = "Page Break"
                    forcedBreak.elementText = ""
                    tmpElements.append(forcedBreak)
                }
                tmpElements.append(element)
                continue
            }

            // Character: collect the entire dialogue block before deciding on page breaks
            if element.elementType == "Character" && i + 1 < maxElements {
                let dialogueBlockTypes: Set<String> = ["Dialogue", "Parenthetical"]

                var j = i + 1
                var nextElement: FNElement = element
                var isEndOfArray = false

                repeat {
                    tmpElements.append(nextElement)
                    if j < maxElements {
                        nextElement = script.elements[j]
                        j += 1
                        if dialogueBlockTypes.contains(nextElement.elementType) {
                            blockHeight += FNPaginator.heightForString(nextElement.elementText, font: font, maxWidth: elementWidth, lineHeight: lineHeight)
                        }
                    } else {
                        isEndOfArray = true
                    }
                } while !isEndOfArray && dialogueBlockTypes.contains(nextElement.elementType)

                if isEndOfArray {
                    i = j - 1
                } else {
                    i = j - 2
                }

                if element.isDualDialogue && previousDualDialogueBlockHeight < 0 {
                    previousDualDialogueBlockHeight = blockHeight
                } else if element.isDualDialogue {
                    let heightDiff = abs(previousDualDialogueBlockHeight - blockHeight)
                    blockHeight = heightDiff
                    previousDualDialogueBlockHeight = -1
                }
            } else {
                tmpElements.append(element)
            }

            let totalHeightUsed = blockHeight + currentY

            if CGFloat(totalHeightUsed) > maxPageHeight {
                // Attempt to split a Character's dialogue block across pages
                if let firstTmp = tmpElements.first,
                   firstTmp.elementType == "Character",
                   CGFloat(totalHeightUsed - Int(maxPageHeight)) >= CGFloat(lineHeight * 4) {

                    var blockIndex     = -1
                    let maxTmpElements = tmpElements.count
                    var partialHeight  = 0
                    let pageOverflow   = totalHeightUsed - Int(maxPageHeight)

                    while partialHeight < pageOverflow && blockIndex < maxTmpElements - 1 {
                        blockIndex += 1
                        let e = tmpElements[blockIndex]
                        let h = FNPaginator.heightForString(e.elementText, font: font, maxWidth: FNPaginator.widthForElement(e), lineHeight: lineHeight)
                        let s = FNPaginator.spaceBeforeForElement(e) * lineHeight
                        partialHeight += h + s
                    }

                    if blockIndex > 0 {
                        let spiller = tmpElements[blockIndex]

                        if spiller.elementType == "Parenthetical" {
                            if blockIndex > 1 {
                                currentPage.append(contentsOf: tmpElements[0..<blockIndex])
                                let more = FNElement()
                                more.elementType = "Character"
                                more.elementText = "(MORE)"
                                currentPage.append(more)
                                pages.append(currentPage)
                                currentPage = []
                                blockHeight = 0

                                let characterCue = tmpElements[0]
                                characterCue.elementText = "\(characterCue.elementText) (CONT'D)"
                                blockHeight += FNPaginator.heightForString(characterCue.elementText, font: font, maxWidth: FNPaginator.widthForElement(characterCue), lineHeight: lineHeight)
                                currentPage.append(characterCue)

                                for z in blockIndex..<maxTmpElements {
                                    let e = tmpElements[z]
                                    currentPage.append(e)
                                    blockHeight += FNPaginator.heightForString(e.elementText, font: font, maxWidth: FNPaginator.widthForElement(e), lineHeight: lineHeight)
                                }
                                currentY = blockHeight
                                tmpElements = []
                            }
                        } else {
                            let distanceToBottom = Int(maxPageHeight) - currentY - lineHeight * 2
                            if distanceToBottom < lineHeight * 5 {
                                pages.append(currentPage)
                                currentPage = []
                                currentY = blockHeight - spaceBefore
                                blockHeight = 0
                                continue
                            }

                            var heightBeforeDialogue = 0
                            for z in 0..<blockIndex {
                                let e = tmpElements[z]
                                heightBeforeDialogue += FNPaginator.spaceBeforeForElement(e)
                                heightBeforeDialogue += FNPaginator.heightForString(e.elementText, font: font, maxWidth: FNPaginator.widthForElement(e), lineHeight: lineHeight)
                            }

                            var dialogueHeight = heightBeforeDialogue
                            var sentenceIndex  = -1
                            let sentences      = spiller.elementText.componentsMatchedByRegex("(.+?[\\.\\?\\!]+\\s*)", capture: 1)
                            let maxSentences   = sentences.count
                            var dialogueBeforeBreak = ""

                            while dialogueHeight < distanceToBottom && sentenceIndex < maxSentences - 1 {
                                sentenceIndex += 1
                                let text = dialogueBeforeBreak + sentences[sentenceIndex]
                                let h = FNPaginator.heightForString(text, font: font, maxWidth: FNPaginator.widthForElement(tmpElements[blockIndex]), lineHeight: lineHeight)
                                dialogueHeight = h
                                if dialogueHeight < distanceToBottom {
                                    dialogueBeforeBreak += sentences[sentenceIndex]
                                }
                            }

                            let preBreakDialogue = FNElement()
                            preBreakDialogue.elementType = "Dialogue"
                            preBreakDialogue.elementText = dialogueBeforeBreak

                            if !preBreakDialogue.elementText.isEmpty {
                                currentPage.append(contentsOf: tmpElements[0..<blockIndex])
                                currentPage.append(preBreakDialogue)
                                let more = FNElement()
                                more.elementType = "Character"
                                more.elementText = "(MORE)"
                                currentPage.append(more)
                                pages.append(currentPage)
                                currentPage = []
                            } else {
                                pages.append(currentPage)
                                currentPage = []
                                for z in 1..<blockIndex {
                                    currentPage.append(tmpElements[z])
                                }
                            }

                            blockHeight = 0

                            let characterCue = FNElement()
                            characterCue.elementType = "Character"
                            characterCue.elementText = tmpElements[0].elementText
                            blockHeight += FNPaginator.heightForString(characterCue.elementText, font: font, maxWidth: FNPaginator.widthForElement(characterCue), lineHeight: lineHeight)
                            currentPage.append(characterCue)

                            let startSentence = max(sentenceIndex, 0)
                            var dialogueAfterBreak = ""
                            for z in startSentence..<maxSentences {
                                dialogueAfterBreak += sentences[z]
                            }

                            let postBreakDialogue = FNElement()
                            postBreakDialogue.elementType = "Dialogue"
                            postBreakDialogue.elementText = dialogueAfterBreak
                            blockHeight += FNPaginator.heightForString(postBreakDialogue.elementText, font: font, maxWidth: FNPaginator.widthForElement(postBreakDialogue), lineHeight: lineHeight)
                            currentPage.append(postBreakDialogue)

                            if blockIndex + 1 < maxTmpElements {
                                for z in (blockIndex + 1)..<maxTmpElements {
                                    let e = tmpElements[z]
                                    currentPage.append(e)
                                    blockHeight += FNPaginator.heightForString(e.elementText, font: font, maxWidth: FNPaginator.widthForElement(e), lineHeight: lineHeight)
                                }
                            }

                            currentY = blockHeight
                            tmpElements = []
                        }
                    } else {
                        pages.append(currentPage)
                        currentPage = []
                        currentY = blockHeight - spaceBefore
                    }
                } else {
                    pages.append(currentPage)
                    currentPage = []
                    currentY = blockHeight - spaceBefore
                    blockHeight = 0
                }
            } else {
                currentY = blockHeight + currentY
            }

            blockHeight = 0
            currentPage.append(contentsOf: tmpElements)
            tmpElements = []
        }

        if !tmpElements.isEmpty {
            currentPage.append(contentsOf: tmpElements)
        }
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
    }

    // MARK: - Helper class methods

    public static func spaceBeforeForElement(_ element: FNElement) -> Int {
        switch element.elementType {
        case "Scene Heading":
            return 2
        case "Action", "General", "Character", "Transition":
            return 1
        default:
            return 0
        }
    }

    public static func leftMarginForElement(_ element: FNElement) -> Int {
        switch element.elementType {
        case "Scene Heading", "Action", "General":
            return 106
        case "Character":
            return 247
        case "Dialogue":
            return 177
        case "Parenthetical":
            return 205
        case "Transition":
            return 106
        default:
            return 0
        }
    }

    public static func widthForElement(_ element: FNElement) -> Int {
        switch element.elementType {
        case "Action", "General", "Scene Heading", "Transition":
            return 430
        case "Character":
            return 250
        case "Dialogue":
            return 250
        case "Parenthetical":
            return 212
        default:
            return 0
        }
    }

    /// Calculates the rendered height of a string using the text layout system.
    /// Counts lines rather than using the bounding box so that line height is respected correctly.
    public static func heightForString(_ string: String, font: PlatformFont, maxWidth: Int, lineHeight: Int) -> Int {
        let textStorage   = NSTextStorage(string: string, attributes: [.font: font])
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: CGFloat(maxWidth), height: .greatestFiniteMagnitude))

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0

        layoutManager.glyphRange(for: textContainer)

        var numberOfLines = 0
        var index = 0
        let numberOfGlyphs = layoutManager.numberOfGlyphs

        while index < numberOfGlyphs {
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }

        return numberOfLines * lineHeight
    }
}
