//
// LocalShareKeyDatasourceTests.swift
// Proton Pass - Created on 16/08/2022.
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

@testable import Client
import Entities
import TestingToolkit
import Testing

@Suite(.tags(.localDatasource))
struct LocalShareKeyDatasourceTests {

    private let sut: LocalShareKeyDatasourceProtocol = LocalShareKeyDatasource(
        databaseService: DatabaseService(inMemory: true)
    )
}

// MARK: - Tests

extension LocalShareKeyDatasourceTests {

    @Test
    func `Returns inserted keys for a specific share`() async throws {
        // Given
        let givenShareId = String.random()
        let givenUserId = String.random()
        let givenShareId2 = String.random()
        let key1 =  SymmetricallyEncryptedShareKey(
            encryptedKey: .random(),
            shareId: givenShareId,
            userId: givenUserId,
            shareKey: .random()
        )
        let givenKeys: [SymmetricallyEncryptedShareKey] = [
            key1,
            SymmetricallyEncryptedShareKey(
                encryptedKey: .random(),
                shareId: givenShareId2,
                userId: givenUserId,
                shareKey: .random()
            )]
        // When
        try await sut.upsertKeys(givenKeys)

        // Then
        let keys = try await sut.getKeys(shareId: givenShareId)
        #expect(keys.count == 1)
        #expect(Set(keys) == Set([key1]))
    }
    
    @Test
    func `Returns all stored keys`() async throws {
        // Given
        let givenShareId = String.random()
        let givenUserId = String.random()
        let givenShareId2 = String.random()
        let givenKeys: [SymmetricallyEncryptedShareKey] = [
            SymmetricallyEncryptedShareKey(
                encryptedKey: .random(),
                shareId: givenShareId,
                userId: givenUserId,
                shareKey: .random()
            ),
            SymmetricallyEncryptedShareKey(
                encryptedKey: .random(),
                shareId: givenShareId2,
                userId: givenUserId,
                shareKey: .random()
            )]
        // When
        try await sut.upsertKeys(givenKeys)

        // Then
        let keys = try await sut.getAllKeys()
        #expect(keys.count == 2)
        #expect(Set(keys) == Set(givenKeys))
    }

    @Test
    func `Upserting multiple batches merges correctly`() async throws {
        // Given
        let shareId = String.random()
        let userId = String.random()

        let firstKeys: [SymmetricallyEncryptedShareKey] = [
            .init(
                encryptedKey: .random(),
                shareId: shareId,
                userId: userId,
                shareKey: .random()
            )
        ]

        let secondKeys: [SymmetricallyEncryptedShareKey] = [
            .init(
                encryptedKey: .random(),
                shareId: shareId,
                userId: userId,
                shareKey: .random()
            )
        ]

        let thirdKeys: [SymmetricallyEncryptedShareKey] = [
            .init(
                encryptedKey: .random(),
                shareId: shareId,
                userId: userId,
                shareKey: .random()
            )
        ]

        let expected = Set(firstKeys + secondKeys + thirdKeys)

        // When
        try await sut.upsertKeys(firstKeys)
        try await sut.upsertKeys(secondKeys)
        try await sut.upsertKeys(thirdKeys)

        // Then
        let keys = try await sut.getKeys(shareId: shareId)
        #expect(Set(keys) == expected)
    }

    @Test
    func `Removing keys only affects targeted user`() async throws {
        // Given
        let userId1 = String.random()
        let shareId1 = String.random()

        let shares1 = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(
                encryptedKey: .random(),
                shareId: shareId1,
                userId: userId1,
                shareKey: .random()
            ))

        let userId2 = String.random()
        let shareId2 = String.random()

        let shares2 = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(
                encryptedKey: .random(),
                shareId: shareId2,
                userId: userId2,
                shareKey: .random()
            ))

        // When
        try await sut.upsertKeys(shares1)
        try await sut.upsertKeys(shares2)

        // Then
        #expect(Set(try await sut.getKeys(shareId: shareId1)) == Set(shares1))
        #expect(Set(try await sut.getKeys(shareId: shareId2)) == Set(shares2))

        // When
        try await sut.removeAllKeys(userId: userId1)

        // Then
        #expect(try await sut.getKeys(shareId: shareId1).isEmpty)
        #expect(Set(try await sut.getKeys(shareId: shareId2)) == Set(shares2))
    }
}
