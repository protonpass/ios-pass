//
// SearchUtilsTests.swift
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

@testable import Core
import Testing

// swiftlint:disable line_length
@Suite(.tags(.utilities))
struct SearchUtilsTests {
    let text = """
    This a very long, meangingless & weird text that helps testing search feature.
    This is how to say "Hello" in some Asian languages: The Japanese say "こんにちは" (konnichiwa), the Chinese say "你好" (nihao) & the Vietnamese say "Xin chào".
    Sometimes words are just not enough to express one's feelings so we can use emoji such AS 👻 and 😢.
    And finally a long, meaningless last line with random comma, and semicolon; and no dot at the End like this
    """

    @Test func `match near the beginning is a leading phrase`() throws {
        // Given
        let query = "long"

        // When
        let searchResult = try #require(SearchUtils.search(query: query, in: text))

        // Then
        #expect(searchResult.matchedPhrase == "This a very long, meangingless & weird text that hel")
        #expect(searchResult.matchedWord == query)
        #expect(searchResult.isLeadingPhrase)
        #expect(!searchResult.isTrailingPhrase)
    }

    @Test func `match near the end is a trailing phrase and keeps the original case`() throws {
        // Given
        let query = "end"

        // When
        let searchResult = try #require(SearchUtils.search(query: query, in: text))

        // Then
        #expect(searchResult.matchedPhrase == "ma, and semicolon; and no dot at the End like this")
        #expect(searchResult.matchedWord == "End")
        #expect(!searchResult.isLeadingPhrase)
        #expect(searchResult.isTrailingPhrase)
    }

    @Test func `query containing an emoji matches case insensitively`() throws {
        // Given
        let query = "as 👻"

        // When
        let searchResult = try #require(SearchUtils.search(query: query, in: text))

        // Then
        #expect(searchResult.matchedPhrase == "s feelings so we can use emoji such AS 👻 and 😢. And finally a long, meaningl")
        #expect(searchResult.matchedWord == "AS 👻")
        #expect(!searchResult.isLeadingPhrase)
        #expect(!searchResult.isTrailingPhrase)
    }

    @Test func `query with non latin characters matches`() throws {
        // Given
        let query = "んにち"

        // When
        let searchResult = try #require(SearchUtils.search(query: query, in: text))

        // Then
        #expect(searchResult.matchedPhrase == " Asian languages: The Japanese say \"こんにちは\" (konnichiwa), the Chinese say \"你好\"")
        #expect(searchResult.matchedWord == query)
        #expect(!searchResult.isLeadingPhrase)
        #expect(!searchResult.isTrailingPhrase)
    }
}

// swiftlint:enable line_length
