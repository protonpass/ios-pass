//
// LocalSpotlightSearchableVaultDatasourceTests.swift
// Proton Pass - Created on 31/01/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

@testable import Client
import XCTest

final class LocalSpotlightSearchableVaultDatasourceTests: XCTestCase {
    var sut: LocalSpotlightSearchableVaultDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalSpotlightSearchableVaultDatasourceTests {
    func testUpdateGetRemoveVaults() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        let shareId1 = String.random()
        let shareId2 = String.random()
        let shareId3 = String.random()
        let shareId4 = String.random()

        // When
        try await sut.setIdsForSearchableVaults(for: userId1, ids: [shareId1, shareId2, shareId3])
        try await sut.setIdsForSearchableVaults(for: userId2, ids: [shareId4])

        // Then
        let user1ShareIds1 = try await sut.getIdsForSearchableVaults(for: userId1)
        let user2ShareIds1 = try await sut.getIdsForSearchableVaults(for: userId2)
        XCTAssertEqual(Set([shareId1, shareId2, shareId3]), Set(user1ShareIds1))
        XCTAssertEqual(Set([shareId4]), Set(user2ShareIds1))

        // When
        try await sut.removeAllSearchableVaults(for: userId1)

        // Then
        let user1ShareIds2 = try await sut.getIdsForSearchableVaults(for: userId1)
        let user2ShareIds2 = try await sut.getIdsForSearchableVaults(for: userId2)
        XCTAssertTrue(user1ShareIds2.isEmpty)
        XCTAssertEqual(Set([shareId4]), Set(user2ShareIds2))
    }
}
