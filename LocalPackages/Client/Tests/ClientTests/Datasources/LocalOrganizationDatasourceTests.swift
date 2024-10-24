//
// LocalOrganizationDatasourceTests.swift
// Proton Pass - Created on 19/03/2024.
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

import Client
import Entities
import XCTest

final class LocalOrganizationDatasourceTests: XCTestCase {
    var sut: LocalOrganizationDatasourceProtocol!

    override func setUp() {
        super.setUp()
        sut = LocalOrganizationDatasource(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalOrganizationDatasourceTests {
    func testUpsertOrganizations() async throws {
        // Given
        // Insert organization for the first time
        let userId = String.random()
        let org1 = Organization(canUpdate: true,
                                settings: .init(shareMode: .restricted,
                                                forceLockSeconds: 100,
                                                exportMode: .admins,
                                                passwordPolicy: PasswordPolicy.default))

        // When
        try await sut.upsertOrganization(org1, userId: userId)
        let result1 = try await XCTUnwrapAsync(await sut.getOrganization(userId: userId))

        // Then
        XCTAssertEqual(result1, org1)

        // Given
        // Override the organization
        let org2 = Organization(canUpdate: false,
                                settings: .init(shareMode: .unrestricted,
                                                forceLockSeconds: 300,
                                                exportMode: .anyone,
                                                passwordPolicy:  PasswordPolicy.default))

        // When
        try await sut.upsertOrganization(org2, userId: userId)
        let result2 = try await XCTUnwrapAsync(await sut.getOrganization(userId: userId))

        // Then
        XCTAssertEqual(result2, org2)
    }

    func testRemoveOrganizations() async throws {
        // Given
        let userId = String.random()
        let org1 = Organization(canUpdate: true,
                                settings: .init(shareMode: .restricted,
                                                forceLockSeconds: 100,
                                                exportMode: .admins,
                                                passwordPolicy: PasswordPolicy.default))

        // When
        try await sut.upsertOrganization(org1, userId: userId)

        // Then
        try await XCTAssertEqualAsync(await sut.getOrganization(userId: userId), org1)

        // When
        try await sut.removeOrganization(userId: userId)

        // Then
        try await XCTAssertNilAsync(await sut.getOrganization(userId: userId))
    }
}
