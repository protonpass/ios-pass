//
// WordProviderTests.swift
// Proton Pass - Created on 09/05/2023.
// Copyright (c) 2023 Proton Technologies AG
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

final class WordProviderTests: XCTestCase {
    func testProvideWords() async throws {
        let sut = try await WordProvider()

        XCTAssertEqual(sut.word(for: .init(first: .four,
                                           second: .three,
                                           third: .one,
                                           fourth: .one,
                                           fifth: .six)), "outweigh")

        XCTAssertEqual(sut.word(for: .init(first: .five,
                                           second: .two,
                                           third: .five,
                                           fourth: .four,
                                           fifth: .one)), "sadness")

        XCTAssertEqual(sut.word(for: .init(first: .three,
                                           second: .two,
                                           third: .one,
                                           fourth: .six,
                                           fifth: .five)), "germinate")
    }
}
