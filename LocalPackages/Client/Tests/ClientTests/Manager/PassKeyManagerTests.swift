//
// PassKeyManagerTests.swift
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
import ClientMocks
import CoreMocks
import CryptoKit
import Entities
import Testing
import Foundation

@Suite(.tags(.manager))
struct PassKeyManagerTests {
    let shareKeyRepository: ShareKeyRepositoryProtocolMock
    let itemKeyDatasource: RemoteItemKeyDatasourceProtocolMock
    let folderKeyDatasource: LocalFolderKeyDatasourceProtocolMock
    let userManager: UserManagerProtocolMock
    let logManager: LogManagerProtocolMock
    let symmetricKeyProviderFactory: SymmetricKeyProviderMockFactory
    let sut: PassKeyManager

    init() {
        shareKeyRepository = ShareKeyRepositoryProtocolMock()
        itemKeyDatasource = RemoteItemKeyDatasourceProtocolMock()
        folderKeyDatasource = LocalFolderKeyDatasourceProtocolMock()
        userManager = UserManagerProtocolMock()
        logManager = LogManagerProtocolMock()
        symmetricKeyProviderFactory = SymmetricKeyProviderMockFactory()
        symmetricKeyProviderFactory.setUp()

        // Setup default stubs for key loading
        shareKeyRepository.stubbedGetAllLocalKeysResult = []
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = []

        sut = PassKeyManager(
            shareKeyRepository: shareKeyRepository,
            itemKeyDatasource: itemKeyDatasource,
            folderKeyDatasource: folderKeyDatasource,
            userManager: userManager,
            logManager: logManager,
            symmetricKeyProvider: symmetricKeyProviderFactory.getProvider()
        )
    }

    // MARK: - getShareKey Tests

    @Test("getShareKey returns cached key when available")
    func getShareKeyCacheHit() async throws {
        // Arrange
        let shareId = "share-1"
        let keyRotation: Int64 = 1
        let keyData = Data(repeating: 0xAB, count: 32)

        // First, get a key to populate the cache
        let shareKey = ShareKey(createTime: 100, key: "test-key", keyRotation: keyRotation, userKeyID: "user-key-1")
        let encryptedKeyBase64 = keyData.encodeBase64()
        let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
        let encryptedShareKey = SymmetricallyEncryptedShareKey(
            encryptedKey: symmetricallyEncryptedKey,
            shareId: shareId,
            userId: "user-1",
            shareKey: shareKey
        )
        shareKeyRepository.stubbedGetKeysResult = [encryptedShareKey]

        // Act - First call populates cache
        let key1 = try await sut.getShareKey(userId: "user-1", shareId: shareId, keyRotation: keyRotation)

        // Reset mock to verify cache is used
        shareKeyRepository.invokedGetKeysCount = 0

        // Act - Second call should use cache
        let key2 = try await sut.getShareKey(userId: "user-1", shareId: shareId, keyRotation: keyRotation)

        // Assert
        #expect(key1.keyRotation == keyRotation)
        #expect(key2.keyRotation == keyRotation)
        #expect(shareKeyRepository.invokedGetKeysCount == 0) // Cache was used
    }

    @Test("getShareKey fetches from repository when not cached")
    func getShareKeyCacheMiss() async throws {
        // Arrange
        let shareId = "share-1"
        let keyRotation: Int64 = 1
        let keyData = Data(repeating: 0xCD, count: 32)

        let shareKey = ShareKey(createTime: 100, key: "test-key", keyRotation: keyRotation, userKeyID: "user-key-1")
        let encryptedKeyBase64 = keyData.encodeBase64()
        let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
        let encryptedShareKey = SymmetricallyEncryptedShareKey(
            encryptedKey: symmetricallyEncryptedKey,
            shareId: shareId,
            userId: "user-1",
            shareKey: shareKey
        )
        shareKeyRepository.stubbedGetKeysResult = [encryptedShareKey]

        // Act
        let key = try await sut.getShareKey(userId: "user-1", shareId: shareId, keyRotation: keyRotation)

        // Assert
        #expect(shareKeyRepository.invokedGetKeys)
        #expect(shareKeyRepository.invokedGetKeysParameters?.shareId == shareId)
        #expect(key.keyRotation == keyRotation)
    }

    @Test("getShareKey throws when key rotation not found")
    func getShareKeyThrowsWhenKeyRotationNotFound() async throws {
        // Arrange
        let shareId = "share-1"
        let requestedRotation: Int64 = 5
        let availableRotation: Int64 = 1

        let shareKey = ShareKey(createTime: 100, key: "test-key", keyRotation: availableRotation, userKeyID: "user-key-1")
        let keyData = Data(repeating: 0xEF, count: 32)
        let encryptedKeyBase64 = keyData.encodeBase64()
        let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
        let encryptedShareKey = SymmetricallyEncryptedShareKey(
            encryptedKey: symmetricallyEncryptedKey,
            shareId: shareId,
            userId: "user-1",
            shareKey: shareKey
        )
        shareKeyRepository.stubbedGetKeysResult = [encryptedShareKey]

        // Act & Assert
        await #expect(throws: PassError.self) {
            try await sut.getShareKey(userId: "user-1", shareId: shareId, keyRotation: requestedRotation)
        }
    }

    // MARK: - getLatestShareKey Tests

    @Test("getLatestShareKey returns cached latest key when available")
    func getLatestShareKeyCacheHit() async throws {
        // Arrange
        let shareId = "share-1"
        let keyRotation: Int64 = 3
        let keyData = Data(repeating: 0x12, count: 32)

        let shareKey = ShareKey(createTime: 100, key: "test-key", keyRotation: keyRotation, userKeyID: "user-key-1")
        let encryptedKeyBase64 = keyData.encodeBase64()
        let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
        let encryptedShareKey = SymmetricallyEncryptedShareKey(
            encryptedKey: symmetricallyEncryptedKey,
            shareId: shareId,
            userId: "user-1",
            shareKey: shareKey
        )
        shareKeyRepository.stubbedGetKeysResult = [encryptedShareKey]

        // Act - First call populates cache
        let key1 = try await sut.getLatestShareKey(userId: "user-1", shareId: shareId)

        // Reset mock to verify cache is used
        shareKeyRepository.invokedGetKeysCount = 0

        // Act - Second call should use cache
        let key2 = try await sut.getLatestShareKey(userId: "user-1", shareId: shareId)

        // Assert
        #expect(key1.keyRotation == keyRotation)
        #expect(key2.keyRotation == keyRotation)
        #expect(shareKeyRepository.invokedGetKeysCount == 0)
    }

    @Test("getLatestShareKey returns key with highest rotation")
    func getLatestShareKeyReturnsHighestRotation() async throws {
        // Arrange
        let shareId = "share-1"
        let keyData = Data(repeating: 0x34, count: 32)
        let encryptedKeyBase64 = keyData.encodeBase64()

        let shareKey1 = ShareKey(createTime: 100, key: "key-1", keyRotation: 1, userKeyID: "user-key-1")
        let shareKey2 = ShareKey(createTime: 200, key: "key-2", keyRotation: 2, userKeyID: "user-key-1")
        let shareKey3 = ShareKey(createTime: 300, key: "key-3", keyRotation: 3, userKeyID: "user-key-1")

        let encryptedKeys = try [shareKey1, shareKey2, shareKey3].map { shareKey in
            let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
            return SymmetricallyEncryptedShareKey(
                encryptedKey: symmetricallyEncryptedKey,
                shareId: shareId,
                userId: "user-1",
                shareKey: shareKey
            )
        }
        shareKeyRepository.stubbedGetKeysResult = encryptedKeys

        // Act
        let key = try await sut.getLatestShareKey(userId: "user-1", shareId: shareId)

        // Assert
        #expect(key.keyRotation == 3)
    }

    // MARK: - getContainerKey Tests

    @Test("getContainerKey returns cached key for specific rotation")
    func getContainerKeyWithRotation() async throws {
        // Arrange - Pre-populate cache via getShareKey
        let shareId = "share-1"
        let keyRotation: Int64 = 2
        let keyData = Data(repeating: 0x56, count: 32)

        let shareKey = ShareKey(createTime: 100, key: "test-key", keyRotation: keyRotation, userKeyID: "user-key-1")
        let encryptedKeyBase64 = keyData.encodeBase64()
        let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
        let encryptedShareKey = SymmetricallyEncryptedShareKey(
            encryptedKey: symmetricallyEncryptedKey,
            shareId: shareId,
            userId: "user-1",
            shareKey: shareKey
        )
        shareKeyRepository.stubbedGetKeysResult = [encryptedShareKey]

        // Pre-populate cache
        _ = try await sut.getShareKey(userId: "user-1", shareId: shareId, keyRotation: keyRotation)

        // Act
        let containerKey = try await sut.getContainerKey(
            userId: "user-1",
            containerId: shareId,
            keyRotation: keyRotation
        )

        // Assert
        #expect(containerKey.keyRotation == keyRotation)
    }

    @Test("getContainerKey returns latest cached key when rotation is nil")
    func getContainerKeyWithoutRotation() async throws {
        // Arrange - Pre-populate cache with multiple rotations
        let shareId = "share-1"
        let keyData = Data(repeating: 0x78, count: 32)
        let encryptedKeyBase64 = keyData.encodeBase64()

        let shareKey1 = ShareKey(createTime: 100, key: "key-1", keyRotation: 1, userKeyID: "user-key-1")
        let shareKey2 = ShareKey(createTime: 200, key: "key-2", keyRotation: 2, userKeyID: "user-key-1")

        let encryptedKeys = try [shareKey1, shareKey2].map { shareKey in
            let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
            return SymmetricallyEncryptedShareKey(
                encryptedKey: symmetricallyEncryptedKey,
                shareId: shareId,
                userId: "user-1",
                shareKey: shareKey
            )
        }
        shareKeyRepository.stubbedGetKeysResult = encryptedKeys

        // Pre-populate cache
        _ = try await sut.getLatestShareKey(userId: "user-1", shareId: shareId)

        // Act
        let containerKey = try await sut.getContainerKey(
            userId: "user-1",
            containerId: shareId,
            keyRotation: nil
        )

        // Assert - Should return key with highest rotation
        #expect(containerKey.keyRotation == 2)
    }

    @Test("getContainerKey throws when key not found")
    func getContainerKeyThrowsWhenNotFound() async throws {
        // Arrange - No keys loaded
        shareKeyRepository.stubbedGetAllLocalKeysResult = []
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = []

        // Act & Assert
        await #expect(throws: PassError.self) {
            try await sut.getContainerKey(
                userId: "user-1",
                containerId: "nonexistent-share",
                keyRotation: 1
            )
        }
    }

    // MARK: - Key Loading Tests

    @Test("Keys are loaded only once even with concurrent calls")
    func keysLoadedOnlyOnce() async throws {
        // Arrange
        let shareId = "share-1"
        let keyData = Data(repeating: 0x9A, count: 32)

        let shareKey = ShareKey(createTime: 100, key: "test-key", keyRotation: 1, userKeyID: "user-key-1")
        let encryptedKeyBase64 = keyData.encodeBase64()
        let symmetricallyEncryptedKey = try symmetricKeyProviderFactory.key.encrypt(encryptedKeyBase64)
        let encryptedShareKey = SymmetricallyEncryptedShareKey(
            encryptedKey: symmetricallyEncryptedKey,
            shareId: shareId,
            userId: "user-1",
            shareKey: shareKey
        )
        shareKeyRepository.stubbedGetAllLocalKeysResult = [encryptedShareKey]
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = []

        // Act - Multiple concurrent calls that trigger key loading
        let keyManager = sut
        try await withThrowingTaskGroup(of: (any CryptographicKeyProtocol).self) { group in
            for _ in 0..<3 {
                group.addTask {
                    try await keyManager.getContainerKey(userId: "user-1", containerId: shareId, keyRotation: nil)
                }
            }
            for try await _ in group {}
        }

        // Assert - getAllLocalKeys should only be called once
        #expect(shareKeyRepository.invokedGetAllLocalKeysCount == 1)
    }

    // MARK: - decryptAndStoreFolderKeys Tests

    @Test("decryptAndStoreFolderKeys does nothing with empty folders")
    func decryptAndStoreFolderKeysWithEmptyFolders() async throws {
        // Act
        try await sut.decryptAndStoreFolderKeys(shareId: "share-1", folders: [])

        // Assert
        #expect(!folderKeyDatasource.invokedUpsertFolderKeysfunction)
    }

    @Test("decryptAndStoreFolderKeys throws when share key not cached")
    func decryptAndStoreFolderKeysThrowsWhenNoShareKey() async throws {
        // Arrange
        let folder = Folder(
            vaultID: "share-1",
            folderID: "folder-1",
            parentFolderID: nil,
            keyRotation: 1,
            folderKey: "encrypted-key",
            contentFormatVersion: 1,
            content: "content"
        )

        // Act & Assert
        await #expect(throws: PassError.self) {
            try await sut.decryptAndStoreFolderKeys(shareId: "share-1", folders: [folder])
        }
    }

    // MARK: - Error Handling Tests

    @Test("getShareKey propagates repository errors")
    func getShareKeyPropagatesErrors() async throws {
        // Arrange
        let expectedError = NSError(domain: "test", code: 1)
        shareKeyRepository.getKeysThrowableError = expectedError

        // Act & Assert
        await #expect(throws: Error.self) {
            try await sut.getShareKey(userId: "user-1", shareId: "share-1", keyRotation: 1)
        }
    }

    @Test("getLatestShareKey propagates repository errors")
    func getLatestShareKeyPropagatesErrors() async throws {
        // Arrange
        let expectedError = NSError(domain: "test", code: 2)
        shareKeyRepository.getKeysThrowableError = expectedError

        // Act & Assert
        await #expect(throws: Error.self) {
            try await sut.getLatestShareKey(userId: "user-1", shareId: "share-1")
        }
    }

    @Test("getLatestShareKey throws when no keys returned")
    func getLatestShareKeyThrowsWhenEmpty() async throws {
        // Arrange
        shareKeyRepository.stubbedGetKeysResult = []

        // Act & Assert
        await #expect(throws: PassError.self) {
            try await sut.getLatestShareKey(userId: "user-1", shareId: "share-1")
        }
    }
}

// MARK: - Helper Extensions

private extension Data {
    func encodeBase64() -> String {
        base64EncodedString()
    }
}
