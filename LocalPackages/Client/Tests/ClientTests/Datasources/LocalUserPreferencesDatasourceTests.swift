//
// LocalUserPreferencesDatasourceTests.swift
// Proton Pass - Created on 29/03/2024.
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
import ClientMocks
import Core
import CryptoKit
import Entities
import XCTest

final class LocalUserPreferencesDatasourceTests: XCTestCase {
    let symmetricKey = SymmetricKey.random()
    var symmetricKeyProvider: SymmetricKeyProvider!
    var sut: LocalUserPreferencesDatasource!

    override func setUp() {
        super.setUp()
        let symmetricKeyProvider = SymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = symmetricKey
        self.symmetricKeyProvider = symmetricKeyProvider
        sut = LocalUserPreferencesDatasource(symmetricKeyProvider: symmetricKeyProvider,
                                             databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        symmetricKeyProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension LocalUserPreferencesDatasourceTests {
    func testGetUpsertRemoveUserPreferences() async throws {
        let userId1 = String.random()
        let pref1a = UserPreferences.random()
        let pref1b = UserPreferences.random()

        let userId2 = String.random()
        let pref2a = UserPreferences.random()
        let pref2b = UserPreferences.random()

        try await sut.upsertPreferences(pref1a, for: userId1)
        try await assertPreferences(pref1a, userId: userId1)
        try await assertCount(1)
        try await assertCount(1, userId: userId1)

        try await sut.upsertPreferences(pref1b, for: userId1)
        try await assertPreferences(pref1b, userId: userId1)
        try await assertCount(1)
        try await assertCount(1, userId: userId1)

        try await sut.upsertPreferences(pref2a, for: userId2)
        try await assertPreferences(pref2a, userId: userId2)
        try await assertCount(2)
        try await assertCount(1, userId: userId1)
        try await assertCount(1, userId: userId2)

        try await sut.upsertPreferences(pref2b, for: userId2)
        try await assertPreferences(pref2b, userId: userId2)
        try await assertCount(2)
        try await assertCount(1, userId: userId1)
        try await assertCount(1, userId: userId2)

        try await sut.removePreferences(for: userId1)
        try await assertCount(1)
        try await assertCount(0, userId: userId1)
        try await assertCount(1, userId: userId2)

        try await sut.removePreferences(for: userId2)
        try await assertCount(0)
        try await assertCount(0, userId: userId1)
        try await assertCount(0, userId: userId2)
    }

    func assertCount(_ expectedCount: Int, userId: String? = nil) async throws {
        let count = try await sut.preferencesCount(userId: userId)
        XCTAssertEqual(count, expectedCount)
    }

    func assertPreferences(_ expectedPreferences: UserPreferences, userId: String) async throws {
        let preferences = try await XCTUnwrapAsync(await sut.getPreferences(for: userId))
        XCTAssertEqual(preferences, expectedPreferences)
    }
}

private extension LocalUserPreferencesDatasource {
    func preferencesCount(userId: String?) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = UserPreferencesEntity.fetchRequest()
        if let userId {
            fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        }
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }
}
