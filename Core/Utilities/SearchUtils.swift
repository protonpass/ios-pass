//
// SearchUtils.swift
// Proton Pass - Created on 21/09/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import Foundation

private let kMatchedPhraseMaxCharacterCount = 40

public struct SearchResult {
    /// The phrase that contains the matched word
    public let matchedPhrase: String

    /// Matched word (search query)
    public let matchedWord: String

    /// Whether the begining of the `matchedPhrase` is also the beginning of the text
    public let isLeadingPhrase: Bool

    /// Whether the ending of the `matchedPhrase` is also the ending of the text
    public let isTrailingPhrase: Bool
}

public enum SearchUtils {
    public static func search(query: String, in text: String) -> SearchResult? {
        let removedNewLinesText = text.replacingOccurrences(of: "\n", with: " ")
        let searchRange = NSRange(location: 0, length: removedNewLinesText.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: query, options: .caseInsensitive),
              let firstMatch = regex.firstMatch(in: removedNewLinesText, range: searchRange) else {
            return nil
        }

        let matchedRange = firstMatch.range
        var startIndex = matchedRange.location
        var endIndex = matchedRange.location + matchedRange.length
        let matchedWord = removedNewLinesText.subString(from: startIndex, to: endIndex)

        while true {
            if startIndex - 1 >= 0 {
                startIndex -= 1
            }

            if endIndex + 1 <= removedNewLinesText.count {
                endIndex += 1
            }

            if (startIndex == 0 && endIndex == removedNewLinesText.count) ||
                (endIndex - startIndex >= kMatchedPhraseMaxCharacterCount) {
                break
            }
        }

        let matchedPhrase = removedNewLinesText.subString(from: startIndex, to: endIndex)

        return .init(matchedPhrase: matchedPhrase,
                     matchedWord: matchedWord,
                     isLeadingPhrase: startIndex == 0,
                     isTrailingPhrase: endIndex == removedNewLinesText.count)
    }
}
