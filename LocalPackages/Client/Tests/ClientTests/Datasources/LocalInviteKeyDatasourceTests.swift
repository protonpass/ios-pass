//
// LocalInviteKeyDatasourceTests.swift
// Proton Pass - Created on 30/07/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Testing

@Suite(.tags(.localDatasource))
struct LocalInviteKeyDatasourceTests {
    let sut: any LocalInviteKeyDatasourceProtocol

    init() {
        self.sut = LocalInviteKeyDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test("Insert and get invite keys")
    func insertAndGet() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        let key1 = InviteKey.random()
        let key2 = InviteKey.random()
        let key3 = InviteKey.random()
        let key4 = InviteKey.random()

        let inviteToken1 = String.random()
        let inviteToken2 = String.random()

        // When
        try await sut.upsertKeys(userId: userId1, inviteToken: inviteToken1, keys: [key1, key2])
        try await sut.upsertKeys(userId: userId2, inviteToken: inviteToken2, keys: [key3, key4])

        let userId1Keys = try await sut.getKeys(userId: userId1, inviteToken: inviteToken1)
        let userId2Keys = try await sut.getKeys(userId: userId2, inviteToken: inviteToken2)

        // Then
        #expect(userId1Keys.count == 2)
        #expect(userId1Keys.contains(key1))
        #expect(userId1Keys.contains(key2))

        #expect(userId2Keys.count == 2)
        #expect(userId2Keys.contains(key3))
        #expect(userId2Keys.contains(key4))
    }

    @Test("Upsert invite keys")
    func upsert() async throws {
        // Given
        let userId = String.random()
        let inviteToken = String.random()

        let key1 = InviteKey.random()
        let key2 = InviteKey.random()
        let key3 = InviteKey.random()
        let key4 = InviteKey.random()

        // When
        try await sut.upsertKeys(userId: userId, inviteToken: inviteToken, keys: [key1, key2])
        let keys1 = try await sut.getKeys(userId: userId, inviteToken: inviteToken)

        // Then
        #expect(keys1.count == 2)
        #expect(keys1.contains(key1))
        #expect(keys1.contains(key2))

        // When
        try await sut.upsertKeys(userId: userId, inviteToken: inviteToken, keys: [key3, key4])
        let keys2 = try await sut.getKeys(userId: userId, inviteToken: inviteToken)

        // Then
        #expect(keys2.count == 2)
        #expect(keys2.contains(key3))
        #expect(keys2.contains(key4))
    }

    @Test("Remove invite keys by userID & inviteToken")
    func removeByUserIdAndInviteToken() async throws {
        // Given
        let userId = String.random()
        let inviteToken = String.random()

        // When
        try await sut.upsertKeys(userId: userId, inviteToken: inviteToken, keys: [.random()])
        try await sut.removeKeys(userId: userId, inviteToken: inviteToken)
        let keys = try await sut.getKeys(userId: userId, inviteToken: inviteToken)

        // Then
        #expect(keys.isEmpty)
    }

    @Test("Remove invite keys by userID")
    func removeByUserId() async throws {
        // Given
        let userId1 = String.random()
        let inviteToken1 = String.random()

        let userId2 = String.random()
        let inviteToken2 = String.random()

        // When
        try await sut.upsertKeys(userId: userId1, inviteToken: inviteToken1, keys: [.random()])
        try await sut.upsertKeys(userId: userId2, inviteToken: inviteToken2, keys: [.random()])
        try await sut.removeKeys(userId: userId1)

        let keys1 = try await sut.getKeys(userId: userId1, inviteToken: inviteToken1)
        let keys2 = try await sut.getKeys(userId: userId2, inviteToken: inviteToken2)

        // Then
        #expect(keys1.isEmpty)
        #expect(keys2.count == 1)
    }
}

private extension InviteKey {
    static func random() -> InviteKey {
        .init(key: .random(), keyRotation: .random(in: 1...100))
    }
}
