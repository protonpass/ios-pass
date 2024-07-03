//
// LocalAccessDatasourceTests.swift
// Proton Pass - Created on 04/05/2023.
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
import Entities
import XCTest

final class LocalAccessDatasourceTests: XCTestCase {
    var sut: LocalAccessDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalAccessDatasourceTests {
    func testUpsertGetAndRemove() async throws {
        // Given
        let givenUserId = String.random()
        let givenAccess = Access(plan: .init(type: "free",
                                             internalName: "test",
                                             displayName: "test",
                                             hideUpgrade: false,
                                             trialEnd: .random(in: 1...100),
                                             vaultLimit: .random(in: 1...100),
                                             aliasLimit: .random(in: 1...100),
                                             totpLimit: .random(in: 1...100)),
                                 monitor: .init(protonAddress: .random(), aliases: .random()),
                                 pendingInvites: 1,
                                 waitingNewUserInvites: 2,
                                 minVersionUpgrade: nil)
        let givenUserAccess = UserAccess(userId: givenUserId, access: givenAccess)
        // When
        try await sut.upsert(access: givenUserAccess)

        // Then
        try await XCTAssertEqualAsync(await sut.getAccess(userId: givenUserId), givenUserAccess)

        // Given
        let updatedAccess = Access(plan: .init(type: "plus",
                                               internalName: "test",
                                               displayName: "test",
                                               hideUpgrade: true,
                                               trialEnd: nil,
                                               vaultLimit: nil,
                                               aliasLimit: nil,
                                               totpLimit: nil), 
                                   monitor: .init(protonAddress: .random(), aliases: .random()),
                                   pendingInvites: 3,
                                   waitingNewUserInvites: 4,
                                   minVersionUpgrade: nil)
        let updatedUserAccess = UserAccess(userId: givenUserId, access: updatedAccess)

        // When
        try await sut.upsert(access: updatedUserAccess)

        // Then
        try await XCTAssertEqualAsync(await sut.getAccess(userId: givenUserId), updatedUserAccess)

        // When
        try await sut.removeAccess(userId: givenUserId)

        // Then
        try await XCTAssertNilAsync(await sut.getAccess(userId: givenUserId))
    }
}
