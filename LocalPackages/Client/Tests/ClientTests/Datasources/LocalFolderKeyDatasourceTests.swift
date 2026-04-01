//
// LocalFolderKeyDatasourceTests.swift
// Proton Pass - Created on 02/02/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import EntitiesMocks
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalFolderKeyDatasourceTests {
    let sut = LocalFolderKeyDatasource(databaseService: DatabaseService(inMemory: true))
}

// MARK: - getAllFolderKeys Tests

extension LocalFolderKeyDatasourceTests {
    @Test("Get all folder keys returns all keys in database")
    func getAllFolderKeys() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        let keysForUser1 = [
            SymmetricallyEncryptedFolderKey.random(userId: userId1),
            SymmetricallyEncryptedFolderKey.random(userId: userId1)
        ]
        let keysForUser2 = [
            SymmetricallyEncryptedFolderKey.random(userId: userId2),
            SymmetricallyEncryptedFolderKey.random(userId: userId2),
            SymmetricallyEncryptedFolderKey.random(userId: userId2)
        ]

        try await sut.upsertFolderKeys(keysForUser1)
        try await sut.upsertFolderKeys(keysForUser2)

        // When
        let allKeys = try await sut.getAllFolderKeys()

        // Then
        #expect(allKeys.count == 5)

        let allFolderIds = Set(allKeys.map(\.folderId))
        let expectedFolderIds = Set((keysForUser1 + keysForUser2).map(\.folderId))
        #expect(allFolderIds == expectedFolderIds)
    }

    @Test("Get all folder keys returns empty when no keys exist")
    func getAllFolderKeysReturnsEmptyWhenNoKeys() async throws {
        // When
        let keys = try await sut.getAllFolderKeys()

        // Then
        #expect(keys.isEmpty)
    }
}

// MARK: - getAllFolderKeys(userId:) Tests

extension LocalFolderKeyDatasourceTests {
    @Test("Get all folder keys by user returns only keys for that user")
    func getAllFolderKeysByUser() async throws {
        // Given
        let userId = String.random()
        let givenKeys = [
            SymmetricallyEncryptedFolderKey.random(userId: userId),
            SymmetricallyEncryptedFolderKey.random(userId: userId),
            SymmetricallyEncryptedFolderKey.random(userId: userId)
        ]

        try await sut.upsertFolderKeys(givenKeys)

        // Add keys for other users
        for _ in 0..<5 {
            try await sut.upsertFolderKeys([.random()])
        }

        // When
        let keys = try await sut.getAllFolderKeys(userId: userId)

        // Then
        #expect(keys.count == givenKeys.count)

        let folderIds = Set(keys.map(\.folderId))
        let givenFolderIds = Set(givenKeys.map(\.folderId))
        #expect(folderIds == givenFolderIds)
    }

    @Test("Get all folder keys by user returns empty for non-existent user")
    func getAllFolderKeysByUserReturnsEmptyForNonExistentUser() async throws {
        // Given
        try await sut.upsertFolderKeys([.random()])

        // When
        let keys = try await sut.getAllFolderKeys(userId: .random())

        // Then
        #expect(keys.isEmpty)
    }
}

// MARK: - upsertFolderKeys Tests

extension LocalFolderKeyDatasourceTests {
    @Test("Insert multiple folder keys")
    func insertFolderKeys() async throws {
        // Given
        let userId = String.random()
        let firstBatch = [
            SymmetricallyEncryptedFolderKey.random(userId: userId),
            SymmetricallyEncryptedFolderKey.random(userId: userId)
        ]
        let secondBatch = [
            SymmetricallyEncryptedFolderKey.random(userId: userId),
            SymmetricallyEncryptedFolderKey.random(userId: userId),
            SymmetricallyEncryptedFolderKey.random(userId: userId)
        ]

        // When
        try await sut.upsertFolderKeys(firstBatch)
        try await sut.upsertFolderKeys(secondBatch)

        // Then
        let keys = try await sut.getAllFolderKeys(userId: userId)
        #expect(keys.count == 5)

        let allGivenFolderIds = Set((firstBatch + secondBatch).map(\.folderId))
        let retrievedFolderIds = Set(keys.map(\.folderId))
        #expect(retrievedFolderIds == allGivenFolderIds)
    }

    @Test("Update existing folder key")
    func updateFolderKey() async throws {
        // Given
        let userId = String.random()
        let folderId = String.random()
        let shareId = String.random()

        let originalKey = SymmetricallyEncryptedFolderKey(
            shareId: shareId,
            encryptedKey: "original-encrypted-key",
            folderId: folderId,
            userId: userId,
            keyRotation: 1
        )
        try await sut.upsertFolderKeys([originalKey])

        // When
        let updatedKey = SymmetricallyEncryptedFolderKey(
            shareId: shareId,
            encryptedKey: "updated-encrypted-key",
            folderId: folderId,
            userId: userId,
            keyRotation: 1
        )
        try await sut.upsertFolderKeys([updatedKey])

        // Then
        let keys = try await sut.getAllFolderKeys(userId: userId)
        #expect(keys.count == 1)

        let key = try #require(keys.first)
        #expect(key.encryptedKey == "updated-encrypted-key")
        #expect(key.keyRotation == 1)
        
        
        
    }

    @Test("Upsert empty array does nothing")
    func upsertEmptyArray() async throws {
        // When
        try await sut.upsertFolderKeys([])

        // Then
        let keys = try await sut.getAllFolderKeys()
        #expect(keys.isEmpty)
    }

    @Test("Upsert keys with same folderId but different userId")
    func upsertKeysWithSameFolderIdDifferentUserId() async throws {
        // Given
        let folderId = String.random()
        let userId1 = String.random()
        let userId2 = String.random()
        let shareId = String.random()

        let key1 = SymmetricallyEncryptedFolderKey(
            shareId: shareId,
            encryptedKey: "key-1",
            folderId: folderId,
            userId: userId1,
            keyRotation: 1
        )
        let key2 = SymmetricallyEncryptedFolderKey(
            shareId: shareId,
            encryptedKey: "key-2",
            folderId: folderId,
            userId: userId2,
            keyRotation: 1
        )

        // When
        try await sut.upsertFolderKeys([key1])
        try await sut.upsertFolderKeys([key2])

        // Then - Due to folderId being the unique identifier, key2 should update key1
        let allKeys = try await sut.getAllFolderKeys()
        #expect(allKeys.count == 1)
        #expect(allKeys.first?.encryptedKey == "key-2")
    }
}

// MARK: - removeAllKeys Tests

extension LocalFolderKeyDatasourceTests {
    @Test("Remove all keys by userId")
    func removeAllKeysByUserId() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        let keysForUser1 = [
            SymmetricallyEncryptedFolderKey.random(userId: userId1),
            SymmetricallyEncryptedFolderKey.random(userId: userId1)
        ]
        let keysForUser2 = [
            SymmetricallyEncryptedFolderKey.random(userId: userId2),
            SymmetricallyEncryptedFolderKey.random(userId: userId2),
            SymmetricallyEncryptedFolderKey.random(userId: userId2)
        ]

        try await sut.upsertFolderKeys(keysForUser1)
        try await sut.upsertFolderKeys(keysForUser2)

        let initialUser1Keys = try await sut.getAllFolderKeys(userId: userId1)
        let initialUser2Keys = try await sut.getAllFolderKeys(userId: userId2)
        #expect(initialUser1Keys.count == 2)
        #expect(initialUser2Keys.count == 3)

        // When
        try await sut.removeAllKeys(userId: userId1)

        // Then
        let user1Keys = try await sut.getAllFolderKeys(userId: userId1)
        let user2Keys = try await sut.getAllFolderKeys(userId: userId2)
        #expect(user1Keys.isEmpty)
        #expect(user2Keys.count == 3)
    }

    @Test("Remove all keys for non-existent user does nothing")
    func removeAllKeysForNonExistentUser() async throws {
        // Given
        let userId = String.random()
        let keys = [
            SymmetricallyEncryptedFolderKey.random(userId: userId),
            SymmetricallyEncryptedFolderKey.random(userId: userId)
        ]
        try await sut.upsertFolderKeys(keys)

        // When
        try await sut.removeAllKeys(userId: .random())

        // Then
        let remainingKeys = try await sut.getAllFolderKeys(userId: userId)
        #expect(remainingKeys.count == 2)
    }
}

// MARK: - Key Rotation Tests

extension LocalFolderKeyDatasourceTests {
    @Test("Multiple key rotations for same folder")
    func multipleKeyRotationsForSameFolder() async throws {
        // Given
        let userId = String.random()
        let folderId = String.random()
        let shareId = String.random()

        // Insert key with rotation 1
        let keyRotation1 = SymmetricallyEncryptedFolderKey(
            shareId: shareId,
            encryptedKey: "key-rotation-1",
            folderId: folderId,
            userId: userId,
            keyRotation: 1
        )
        try await sut.upsertFolderKeys([keyRotation1])

        // Update with rotation 2
        let keyRotation2 = SymmetricallyEncryptedFolderKey(
            shareId: shareId,
            encryptedKey: "key-rotation-2",
            folderId: folderId,
            userId: userId,
            keyRotation: 2
        )
        try await sut.upsertFolderKeys([keyRotation2])

        // When
        let keys = try await sut.getAllFolderKeys(userId: userId)

        // Then - Should have only one key (latest rotation)
        #expect(keys.count == 2)
        let key = try #require(keys.last)
        #expect(key.keyRotation == 2)
        #expect(key.encryptedKey == "key-rotation-2")
    }
}

// MARK: - Helper Extension

private extension LocalFolderKeyDatasource {
    @discardableResult
    func givenInsertedFolderKey(folderId: String? = nil,
                                userId: String? = nil,
                                keyRotation: Int64? = nil) async throws -> SymmetricallyEncryptedFolderKey {
        let key = SymmetricallyEncryptedFolderKey(
            shareId: .random(),
            encryptedKey: .random(),
            folderId: folderId ?? .random(),
            userId: userId ?? .random(),
            keyRotation: keyRotation ?? .random(in: 1...100)
        )
        try await upsertFolderKeys([key])
        return key
    }
}
