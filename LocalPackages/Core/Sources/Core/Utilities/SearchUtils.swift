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

public struct SearchResult: Sendable, Hashable {
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
        // Remove new lines because search results are for preview purpose
        // we don't want to have new lines in such case
        let text = text.replacingOccurrences(of: "\n", with: " ")

        guard let range = text.range(of: query, options: .caseInsensitive) else { return nil }
        let matchedWord = text[range]

        // We want to extract the matched phrase that has
        // a predefined number of surrounding characters around the matchedWord
        let offset = 40
        let matchedPhraseUpperIndex = text.index(range.upperBound,
                                                 offsetBy: -offset,
                                                 limitedBy: text.startIndex) ?? text.startIndex
        let matchedPhraseLowerIndex = text.index(range.lowerBound,
                                                 offsetBy: offset,
                                                 limitedBy: text.endIndex) ?? text.endIndex
        let matchedPhrase = text[matchedPhraseUpperIndex..<matchedPhraseLowerIndex]

        return .init(matchedPhrase: String(matchedPhrase),
                     matchedWord: String(matchedWord),
                     isLeadingPhrase: matchedPhraseUpperIndex == text.startIndex,
                     isTrailingPhrase: matchedPhraseLowerIndex == text.endIndex)
    }
}
