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
import Core
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import Testing
import Foundation

@Suite(.tags(.manager))
struct PassKeyManagerTests {
    let shareKeyRepository: ShareKeyRepositoryProtocolMock
    let itemKeyDatasource: RemoteItemKeyDatasourceProtocolMock
    let folderKeyDatasource: LocalFolderKeyDatasourceProtocolMock
    let logManager: LogManagerProtocolMock
    let symmetricKeyProviderFactory: SymmetricKeyProviderMockFactory
    let sut: PassKeyManager

    init() {
        shareKeyRepository = ShareKeyRepositoryProtocolMock()
        itemKeyDatasource = RemoteItemKeyDatasourceProtocolMock()
        folderKeyDatasource = LocalFolderKeyDatasourceProtocolMock()
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
            userId: "user-1", shareId: shareId, folderId: nil,
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
            userId: "user-1", shareId: shareId, folderId: nil,
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
                userId: "user-1", shareId: "nonexistent-share", folderId: nil,
                keyRotation: 1
            )
        }
    }

    // MARK: - Key Loading Tests

    @Test("All accounts share one preload even with concurrent calls")
    func keysLoadedOnlyOnce() async throws {
        let a = Data(repeating: 0x9A, count: 32)
        let b = Data(repeating: 0x9B, count: 32)
        shareKeyRepository.stubbedGetAllLocalKeysResult = [
            try encryptedShare(user: "A", share: "share-A", bytes: a),
            try encryptedShare(user: "B", share: "share-B", bytes: b)
        ]
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = []

        let keyManager = sut
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (userId, shareId, expected) in [("A", "share-A", a), ("B", "share-B", b), ("A", "share-A", a)] {
                group.addTask {
                    let key = try await keyManager.getContainerKey(userId: userId, shareId: shareId, folderId: nil)
                    #expect(key.keyData == expected)
                }
            }
            try await group.waitForAll()
        }

        #expect(shareKeyRepository.invokedGetAllLocalKeysCount == 1)
        #expect(folderKeyDatasource.invokedGetAllFolderKeysAsyncCount1 == 1)
    }

    // MARK: - decryptAndStoreFolderKeys Tests

    @Test("decryptAndStoreFolderKeys does nothing with empty folders")
    func decryptAndStoreFolderKeysWithEmptyFolders() async throws {
        // Act
        try await sut.decryptAndStoreFolderKeys(userId: "user-1", shareId: "share-1", folders: [])

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
            try await sut.decryptAndStoreFolderKeys(userId: "user-1", shareId: "share-1", folders: [folder])
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

extension PassKeyManagerTests {
    @Test func uniqueShareIDsKeepAccountKeysDistinct() async throws {
        let a = Data(repeating: 0x11, count: 32)
        let b = Data(repeating: 0x22, count: 32)
        shareKeyRepository.stubbedGetAllLocalKeysResult = [
            try encryptedShare(user: "A", share: "share-A", bytes: a),
            try encryptedShare(user: "B", share: "share-B", bytes: b)
        ]
        let keyA = try await sut.getContainerKey(userId: "A", shareId: "share-A", folderId: nil)
        let keyB = try await sut.getContainerKey(userId: "B", shareId: "share-B", folderId: nil)
        #expect(keyA.keyData == a)
        #expect(keyB.keyData == b)
        #expect(try await sut.getContainerKey(userId: "A", shareId: "share-A", folderId: nil).keyData == a)
        #expect(shareKeyRepository.invokedRefreshKeysCount == 0)
        #expect(shareKeyRepository.invokedGetAllLocalKeysCount == 1)
        #expect(folderKeyDatasource.invokedGetAllFolderKeysAsyncCount1 == 1)
    }

    @Test func rootsAndSameFolderIDInDifferentSharesUseDistinctKeys() async throws {
        let rootA = Data(repeating: 0x31, count: 32)
        let rootB = Data(repeating: 0x32, count: 32)
        let folderA = Data(repeating: 0x33, count: 32)
        let folderB = Data(repeating: 0x34, count: 32)
        shareKeyRepository.stubbedGetAllLocalKeysResult = [
            try encryptedShare(user: "A", share: "share-A", bytes: rootA),
            try encryptedShare(user: "B", share: "share-B", bytes: rootB)
        ]
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = [
            try encryptedFolder(user: "A", share: "share-A", folder: "folder", bytes: folderA),
            try encryptedFolder(user: "B", share: "share-B", folder: "folder", bytes: folderB)
        ]
        #expect(try await sut.getContainerKey(userId: "A", shareId: "share-A", folderId: nil).keyData == rootA)
        #expect(try await sut.getContainerKey(userId: "A", shareId: "share-A", folderId: "folder").keyData == folderA)
        #expect(try await sut.getContainerKey(userId: "B", shareId: "share-B", folderId: nil).keyData == rootB)
        #expect(try await sut.getContainerKey(userId: "B", shareId: "share-B", folderId: "folder").keyData == folderB)
        #expect(try await sut.getContainerKey(userId: "A", shareId: "share-A", folderId: "folder").keyData == folderA)
        #expect(shareKeyRepository.invokedRefreshKeysCount == 0)
    }

    @Test func refreshUsesRequestedAccountAndRawShareID() async throws {
        let bytes = Data(repeating: 0x41, count: 32)
        shareKeyRepository.stubbedRefreshKeysResult = [try encryptedShare(user: "B", share: "raw-share", bytes: bytes)]
        let key = try await sut.getContainerKey(userId: "B", shareId: "raw-share", folderId: nil)
        #expect(key.keyData == bytes)
        #expect(shareKeyRepository.invokedRefreshKeysParameters?.userId == "B")
        #expect(shareKeyRepository.invokedRefreshKeysParameters?.shareId == "raw-share")
        #expect(shareKeyRepository.invokedRefreshKeysCount == 1)
    }

    @Test func missingFolderNeverCallsShareKeyAPI() async throws {
        await #expect(throws: PassError.self) {
            try await sut.getContainerKey(userId: "B", shareId: "share-B", folderId: "folder", keyRotation: 1)
        }
        #expect(shareKeyRepository.invokedRefreshKeysCount == 0)
    }

    @Test func foreignAccountRepositoryMaterialCannotSatisfyLookup() async throws {
        shareKeyRepository.stubbedGetKeysResult = [try encryptedShare(user: "A", share: "share-A", bytes: Data(repeating: 7, count: 32))]
        await #expect(throws: PassError.self) {
            try await sut.getShareKey(userId: "B", shareId: "share-B", keyRotation: 1)
        }
    }

    @Test func folderKeysPersistUnderRequestedAccount() async throws {
        let root = Data(repeating: 0x51, count: 32)
        let folderBytes = Data(repeating: 0x52, count: 32)
        shareKeyRepository.stubbedRefreshKeysResult = [try encryptedShare(user: "B", share: "share-B", bytes: root)]
        let ciphertext = try AES.GCM.seal(folderBytes, key: root, associatedData: .folderKey)
        let folder = Folder(vaultID: "vault", folderID: "folder", parentFolderID: nil,
                            keyRotation: 1, folderKey: ciphertext.base64EncodedString(),
                            contentFormatVersion: 1, content: "unused")
        try await sut.decryptAndStoreFolderKeys(userId: "B", shareId: "share-B", folders: [folder])
        let saved = try #require(folderKeyDatasource.invokedUpsertFolderKeysParameters?.keys.first)
        #expect(saved.userId == "B")
        #expect(saved.shareId == "share-B")
        #expect(saved.folderId == "folder")
        let decrypted = try symmetricKeyProviderFactory.key.decrypt(saved.encryptedKey)
        #expect(decrypted == folderBytes.base64EncodedString())
        #expect(shareKeyRepository.invokedRefreshKeysParameters?.userId == "B")
    }

    @Test func everyItemKeyAPIPreservesFolderAndAccountIdentity() async throws {
        let wrongRoot = Data(repeating: 0x61, count: 32)
        let folderBytes = Data(repeating: 0x62, count: 32)
        let foreignFolder = Data(repeating: 0x63, count: 32)
        let itemBytes = Data(repeating: 0x64, count: 32)
        shareKeyRepository.stubbedGetAllLocalKeysResult = [try encryptedShare(user: "B", share: "share-B", bytes: wrongRoot)]
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = [
            try encryptedFolder(user: "B", share: "share-B", folder: "folder", bytes: folderBytes),
            try encryptedFolder(user: "A", share: "share-A", folder: "folder", bytes: foreignFolder)
        ]
        let ciphertext = try AES.GCM.seal(itemBytes, key: folderBytes, associatedData: .itemKey)
        let key = ItemKey(key: ciphertext.base64EncodedString(), keyRotation: 1)
        itemKeyDatasource.stubbedGetLatestKeyResult = key
        itemKeyDatasource.stubbedGetAllKeysResult = [key]
        let latest = try await sut.getLatestItemKey(userId: "B", shareId: "share-B", folderId: "folder", itemId: "item")
        let exact = try await sut.getItemKey(userId: "B", shareId: "share-B", folderId: "folder", itemId: "item", keyRotation: 1)
        let all = try await sut.getItemKeys(userId: "B", shareId: "share-B", folderId: "folder", itemId: "item")
        #expect(latest.keyData == itemBytes)
        #expect(exact.keyData == itemBytes)
        #expect(all.map(\.keyData) == [itemBytes])
        #expect((latest as? DecryptedItemKey)?.containerId == "foldershare-B")
        #expect((exact as? DecryptedItemKey)?.containerId == "foldershare-B")
        #expect(all.compactMap { ($0 as? DecryptedItemKey)?.containerId } == ["foldershare-B"])
        #expect(itemKeyDatasource.invokedGetLatestKeyParameters?.userId == "B")
        #expect(itemKeyDatasource.invokedGetAllKeysParameters?.userId == "B")
        await #expect(throws: Error.self) {
            try await sut.getItemKey(userId: "B", shareId: "share-B", folderId: nil, itemId: "item", keyRotation: 1)
        }
    }

    private func encryptedShare(user: String, share: String, bytes: Data) throws -> SymmetricallyEncryptedShareKey {
        .init(encryptedKey: try symmetricKeyProviderFactory.key.encrypt(bytes.base64EncodedString()),
              shareId: share, userId: user,
              shareKey: .init(createTime: 1, key: "unused", keyRotation: 1, userKeyID: "unused"))
    }

    private func encryptedFolder(user: String, share: String, folder: String, bytes: Data) throws -> SymmetricallyEncryptedFolderKey {
        .init(shareId: share, encryptedKey: try symmetricKeyProviderFactory.key.encrypt(bytes.base64EncodedString()),
              folderId: folder, userId: user, keyRotation: 1)
    }
}

extension PassKeyManagerTests {
    @Test(.timeLimit(.minutes(1)))
    func anotherAccountLookupDuringFolderRefreshDoesNotChangeOwnership() async throws {
        let accountA = Data(repeating: 0x81, count: 32)
        let accountB = Data(repeating: 0x82, count: 32)
        let folderBytes = Data(repeating: 0x83, count: 32)
        let repository = SuspendedKeyRepository(local: try encryptedShare(user: "A", share: "share-A", bytes: accountA),
                                                remote: try encryptedShare(user: "B", share: "share-B", bytes: accountB))
        let manager = PassKeyManager(shareKeyRepository: repository, itemKeyDatasource: itemKeyDatasource,
                                     folderKeyDatasource: folderKeyDatasource, logManager: logManager,
                                     symmetricKeyProvider: symmetricKeyProviderFactory.getProvider())
        let wrapped = try AES.GCM.seal(folderBytes, key: accountB, associatedData: .folderKey)
        let folder = Folder(vaultID: "vault", folderID: "folder", parentFolderID: nil, keyRotation: 1,
                            folderKey: wrapped.base64EncodedString(), contentFormatVersion: 1, content: "unused")
        let refresh = Task { try await manager.decryptAndStoreFolderKeys(userId: "B", shareId: "share-B", folders: [folder]) }
        await repository.entered.wait()
        #expect(try await manager.getContainerKey(userId: "A", shareId: "share-A", folderId: nil).keyData == accountA)
        await repository.release.open()
        try await refresh.value
        #expect(folderKeyDatasource.invokedUpsertFolderKeysParameters?.keys.first?.userId == "B")
        #expect(try await manager.getContainerKey(userId: "A", shareId: "share-A", folderId: nil).keyData == accountA)
        #expect(try await manager.getContainerKey(userId: "B", shareId: "share-B", folderId: "folder").keyData == folderBytes)
        #expect(await repository.requestedUser == "B")
    }
}

private actor KeyLookupGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func open() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }
}

private actor SuspendedKeyRepository: ShareKeyRepositoryProtocol {
    let entered = KeyLookupGate()
    let release = KeyLookupGate()
    let local: SymmetricallyEncryptedShareKey
    let remote: SymmetricallyEncryptedShareKey
    private(set) var requestedUser: String?
    init(local: SymmetricallyEncryptedShareKey, remote: SymmetricallyEncryptedShareKey) {
        self.local = local
        self.remote = remote
    }
    func getAllLocalKeys() async throws -> [SymmetricallyEncryptedShareKey] { [local] }
    func getKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey] { [local] }
    func refreshKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        requestedUser = userId
        await entered.open()
        await release.wait()
        return [remote]
    }
    func deleteAllUserShareKeysLocally(userId: String) async throws {}
}

extension PassKeyManagerTests {
    @Test func attachmentKeysForItemShareIgnoreVaultFolderMetadata() async throws {
        let shareBytes = Data(repeating: 0x91, count: 32)
        let folderBytes = Data(repeating: 0x92, count: 32)
        shareKeyRepository.stubbedGetKeysResult = [try encryptedShare(user: "B", share: "share-B", bytes: shareBytes)]
        folderKeyDatasource.stubbedGetAllFolderKeysAsyncResult1 = [
            try encryptedFolder(user: "B", share: "share-B", folder: "folder", bytes: folderBytes)
        ]
        let share = Share.random(shareID: "share-B", targetType: 2)
        #expect(share.shareType == .item)
        let keys = try await sut.getShareKeys(userId: "B", share: share,
                                              item: DummyItemIdentifiable(itemId: "item", shareId: "share-B", folderId: "folder"))
        #expect(keys.map(\.keyData) == [shareBytes])
        #expect(itemKeyDatasource.invokedGetAllKeysCount == 0)
    }
}
