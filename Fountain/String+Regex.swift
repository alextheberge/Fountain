//
//  String+Regex.swift
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

extension String {

    func isMatchedByRegex(_ pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }

    public func replacingOccurrencesOfRegex(_ pattern: String, withString template: String, options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return self }
        let range = NSRange(self.startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }

    // Returns an NSRange for the first match of the pattern.
    func nsRangeOfRegex(_ pattern: String) -> NSRange {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return NSRange(location: NSNotFound, length: 0)
        }
        let range = NSRange(self.startIndex..., in: self)
        return regex.rangeOfFirstMatch(in: self, options: [], range: range)
    }

    // Returns the text of the specified capture group for the first match.
    func stringByMatching(_ pattern: String, capture: Int, options: NSRegularExpression.Options = []) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let nsRange = NSRange(self.startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: nsRange) else { return nil }
        let captureRange = match.range(at: capture)
        guard captureRange.location != NSNotFound, let swiftRange = Range(captureRange, in: self) else { return nil }
        return String(self[swiftRange])
    }

    // Returns the text of the specified capture group for every match.
    public func componentsMatchedByRegex(_ pattern: String, capture: Int) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(self.startIndex..., in: self)
        let matches = regex.matches(in: self, options: [], range: nsRange)
        return matches.compactMap { match -> String? in
            let captureRange = match.range(at: capture)
            guard captureRange.location != NSNotFound, let swiftRange = Range(captureRange, in: self) else { return nil }
            return String(self[swiftRange])
        }
    }
}
