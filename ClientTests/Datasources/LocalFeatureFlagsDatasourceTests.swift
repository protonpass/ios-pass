//
// LocalFeatureFlagsDatasourceTests.swift
// Proton Pass - Created on 09/06/2023.
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

@testable import Client
import XCTest

final class LocalFeatureFlagsDatasourceTests: XCTestCase {
    var sut: LocalFeatureFlagsDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalFeatureFlagsDatasourceTests {
    func testUpsertAndGetFlags() async throws {
        // Given
        let givenUserId = String.random()
        let givenFlags = FeatureFlags(creditCardV1: .random(), customFields: .random())

        // When
        try await sut.upsertFlags(givenFlags, userId: givenUserId)
        let flags = try await sut.getFeatureFlags(userId: givenUserId)
        let nonNilFlags = try XCTUnwrap(flags)

        // Then
        XCTAssertEqual(nonNilFlags, givenFlags)
    }
}
