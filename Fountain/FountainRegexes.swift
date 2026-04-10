//
//  FountainRegexes.swift
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

// MARK: - Line breaks

let UNIVERSAL_LINE_BREAKS_PATTERN  = "\\r\\n|\\r|\\n"
let UNIVERSAL_LINE_BREAKS_TEMPLATE = "\n"

// MARK: - Match patterns

let SCENE_HEADER_PATTERN       = "(?<=\\n)(([iI][nN][tT]|[eE][xX][tT]|[^\\w][eE][sS][tT]|\\.|[iI]\\.?\\/[eE]\\.?)([^\\n]+))\\n"
let ACTION_PATTERN             = "([^<>]*?)(\\n{2}|\\n<)"
let MULTI_LINE_ACTION_PATTERN  = "\n{2}(([^a-z\\n:]+?[\\.\\?,\\s!\\*_]*?)\n{2}){1,2}"
let CHARACTER_CUE_PATTERN      = "(?<=\\n)([ \\t]*[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?)\\n{1}(?!\\n)"
let DIALOGUE_PATTERN           = "(<(Character|Parenthetical)>[^<>\\n]+<\\/(Character|Parenthetical)>)([^<>]*?)(?=\\n{2}|\\n{1}<Parenthetical>)"
let PARENTHETICAL_PATTERN      = "(\\([^<>]*?\\)[\\s]?)\n"
let TRANSITION_PATTERN         = "\\n([\\*_]*([^<>\\na-z]*TO:|FADE TO BLACK\\.|FADE OUT\\.|CUT TO BLACK\\.)[\\*_]*)\\n"
let FORCED_TRANSITION_PATTERN  = "\\n((&gt;|>)\\s*[^<>\\n]+)\\n"
let FALSE_TRANSITION_PATTERN   = "\\n((&gt;|>)\\s*[^<>\\n]+(&lt;\\s*))\\n"
let PAGE_BREAK_PATTERN         = "(?<=\\n)(\\s*[\\=\\-\\_]{3,8}\\s*)\\n{1}"
let CLEANUP_PATTERN            = "<Action>\\s*<\\/Action>"
let FIRST_LINE_ACTION_PATTERN  = "^\\n\\n([^<>\\n#]*?)\\n"
let SCENE_NUMBER_PATTERN       = "(\\#([0-9A-Za-z\\.\\)-]+)\\#)"
let SECTION_HEADER_PATTERN     = "((#+)(\\s*[^\\n]*))\\n?"

// MARK: - Templates

let SCENE_HEADER_TEMPLATE      = "\n<Scene Heading>$1</Scene Heading>"
let ACTION_TEMPLATE            = "<Action>$1</Action>$2"
let MULTI_LINE_ACTION_TEMPLATE = "\n<Action>$2</Action>"
let CHARACTER_CUE_TEMPLATE     = "<Character>$1</Character>"
let DIALOGUE_TEMPLATE          = "$1<Dialogue>$4</Dialogue>"
let PARENTHETICAL_TEMPLATE     = "<Parenthetical>$1</Parenthetical>"
let TRANSITION_TEMPLATE        = "\n<Transition>$1</Transition>"
let FORCED_TRANSITION_TEMPLATE = "\n<Transition>$1</Transition>"
let FALSE_TRANSITION_TEMPLATE  = "\n<Action>$1</Action>"
let PAGE_BREAK_TEMPLATE        = "\n<Page Break></Page Break>\n"
let CLEANUP_TEMPLATE           = ""
let FIRST_LINE_ACTION_TEMPLATE = "<Action>$1</Action>\n"
let SECTION_HEADER_TEMPLATE    = "<Section Heading>$1</Section Heading>"

// MARK: - Comments

let BLOCK_COMMENT_PATTERN      = "\\n\\/\\*([^<>]+?)\\*\\/\\n"
let BRACKET_COMMENT_PATTERN    = "\\n\\[{2}([^<>]+?)\\]{2}\\n"
let SYNOPSIS_PATTERN           = "\\n={1}([^<>=][^<>]+?)\\n"

let BLOCK_COMMENT_TEMPLATE     = "\n<Boneyard>$1</Boneyard>\n"
let BRACKET_COMMENT_TEMPLATE   = "\n<Comment>$1</Comment>\n"
let SYNOPSIS_TEMPLATE          = "\n<Synopsis>$1</Synopsis>\n"

let NEWLINE_REPLACEMENT        = "@@@@@"
let NEWLINE_RESTORE            = "\n"

// MARK: - Title page

let TITLE_PAGE_PATTERN           = "^([^\\n]+:(([ \\t]*|\\n)[^\\n]+\\n)+)+\\n"
let INLINE_DIRECTIVE_PATTERN     = "^([\\w\\s&]+):\\s*([^\\s][\\w&,\\.\\?!:\\(\\)\\/\\s-©\\*\\_]+)$"
let MULTI_LINE_DIRECTIVE_PATTERN = "^([\\w\\s&]+):\\s*$"
let MULTI_LINE_DATA_PATTERN      = "^([ ]{2,8}|\\t)([^<>]+)$"

// MARK: - Misc

let DUAL_DIALOGUE_PATTERN  = "\\^\\s*$"
let CENTERED_TEXT_PATTERN  = "^>[^<>\\n]+<"

// MARK: - Styling patterns (for FDX / HTML)
// Public so `FountainHTML` (separate SwiftPM target) can share the same patterns as the parser.

public let BOLD_ITALIC_UNDERLINE_PATTERN = "(_\\*{3}|\\*{3}_)([^<>]+)(_\\*{3}|\\*{3}_)"
public let BOLD_ITALIC_PATTERN           = "(\\*{3})([^<>]+)(\\*{3})"
public let BOLD_UNDERLINE_PATTERN        = "(_\\*{2}|\\*{2}_)([^<>]+)(_\\*{2}|\\*{2}_)"
public let ITALIC_UNDERLINE_PATTERN      = "(_\\*{1}|\\*{1}_)([^<>]+)(_\\*{1}|\\*{1}_)"
public let BOLD_PATTERN                  = "(\\*{2})([^<>]+)(\\*{2})"
public let ITALIC_PATTERN                = "(?<!\\\\)(\\*{1})([^<>]+)(\\*{1})"
public let UNDERLINE_PATTERN             = "(_)([^<>_]+)(_)"

// MARK: - Styling templates

let BOLD_ITALIC_UNDERLINE_TEMPLATE = "Bold+Italic+Underline"
let BOLD_ITALIC_TEMPLATE           = "Bold+Italic"
let BOLD_UNDERLINE_TEMPLATE        = "Bold+Underline"
let ITALIC_UNDERLINE_TEMPLATE      = "Italic+Underline"
let BOLD_TEMPLATE                  = "Bold"
let ITALIC_TEMPLATE                = "Italic"
let UNDERLINE_TEMPLATE             = "Underline"
