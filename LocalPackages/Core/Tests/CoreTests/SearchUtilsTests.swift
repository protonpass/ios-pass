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
import XCTest

// swiftlint:disable line_length
final class SearchUtilsTests: XCTestCase {
    let text = """
    This a very long, meangingless & weird text that helps testing search feature.
    This is how to say "Hello" in some Asian languages: The Japanese say "こんにちは" (konnichiwa), the Chinese say "你好" (nihao) & the Vietnamese say "Xin chào".
    Sometimes words are just not enough to express one's feelings so we can use emoji such AS 👻 and 😢.
    And finally a long, meaningless last line with random comma, and semicolon; and no dot at the End like this
    """

    func testSearchWithResultInTheBegining() throws {
        continueAfterFailure = false

        // Given
        let query = "long"

        // When
        let searchResult = try XCTUnwrap(SearchUtils.search(query: query, in: text))

        // Then
        XCTAssertEqual(searchResult.matchedPhrase, "This a very long, meangingless & weird text that hel")
        XCTAssertEqual(searchResult.matchedWord, query)
        XCTAssertTrue(searchResult.isLeadingPhrase)
        XCTAssertFalse(searchResult.isTrailingPhrase)
    }

    func testSearchWithResultInTheEnding() throws {
        continueAfterFailure = false

        // Given
        let query = "end"

        // When
        let searchResult = try XCTUnwrap(SearchUtils.search(query: query, in: text))

        // Then
        XCTAssertEqual(searchResult.matchedPhrase, "ma, and semicolon; and no dot at the End like this")
        XCTAssertEqual(searchResult.matchedWord, "End")
        XCTAssertFalse(searchResult.isLeadingPhrase)
        XCTAssertTrue(searchResult.isTrailingPhrase)
    }

    func testSearchWithEmoji() throws {
        continueAfterFailure = false

        // Given
        let query = "as 👻"

        // When
        let searchResult = try XCTUnwrap(SearchUtils.search(query: query, in: text))

        // Then
        XCTAssertEqual(searchResult.matchedPhrase,
                       "s feelings so we can use emoji such AS 👻 and 😢. And finally a long, meaningl")
        XCTAssertEqual(searchResult.matchedWord, "AS 👻")
        XCTAssertFalse(searchResult.isLeadingPhrase)
        XCTAssertFalse(searchResult.isTrailingPhrase)
    }

    func testSearchWithNonAlphabetCharacters() throws {
        continueAfterFailure = false

        // Given
        let query = "んにち"

        // When
        let searchResult = try XCTUnwrap(SearchUtils.search(query: query, in: text))

        // Then
        XCTAssertEqual(searchResult.matchedPhrase,
                       " Asian languages: The Japanese say \"こんにちは\" (konnichiwa), the Chinese say \"你好\"")
        XCTAssertEqual(searchResult.matchedWord, query)
        XCTAssertFalse(searchResult.isLeadingPhrase)
        XCTAssertFalse(searchResult.isTrailingPhrase)
    }
}
