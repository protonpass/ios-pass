//
// PassKeyManager.swift
// Proton Pass - Created on 24/02/2023.
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

import Core
@preconcurrency import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin

// sourcery: AutoMockable
public protocol PassKeyManagerProtocol: Sendable, AnyObject {
    func getShareKey(userId: String,
                     shareId: String,
                     keyRotation: Int64) async throws -> any CryptographicKeyProtocol

    func getLatestShareKey(userId: String, shareId: String) async throws -> any CryptographicKeyProtocol

    func getShareKeys(userId: String,
                      share: Share,
                      item: any ItemIdentifiable) async throws -> [any CryptographicKeyProtocol]

    func getLatestItemKey(userId: String,
                          shareId: String,
                          parentId: String,
                          itemId: String) async throws -> any CryptographicKeyProtocol

    func getItemKeys(userId: String,
                     shareId: String,
                     parentId: String,
                     itemId: String) async throws -> [any CryptographicKeyProtocol]

    func getItemKey(userId: String,
                    shareId: String,
                    parentId: String,
                    itemId: String,
                    keyRotation: Int64) async throws -> any CryptographicKeyProtocol

    func decryptAndStoreFolderKeys(shareId: String, folders: [Folder]) async throws

    func getContainerKey(containerId: String,
                         keyRotation: Int64?) async throws -> any CryptographicKeyProtocol
}

public actor PassKeyManager: PassKeyManagerProtocol {
    private let userManager: any UserManagerProtocol
    private let shareKeyRepository: any ShareKeyRepositoryProtocol
    private let itemKeyDatasource: any RemoteItemKeyDatasourceProtocol
    private let folderKeyDatasource: any LocalFolderKeyDatasourceProtocol
    private let logger: Logger
    private let symmetricKeyProvider: any SymmetricKeyProvider

    /// Cache structure: containerId -> (keyRotation -> decryptedKey)
    /// This allows O(1) lookup for specific rotations and O(n) for finding latest (n = rotation count, typically
    /// small)
    private var keyCache = [String: [Int64: any CryptographicKeyProtocol]]()
    private var keysLoaded = false
    private var loadingTask: Task<Void, Error>?

    private var symmetricKey: SymmetricKey {
        get async throws {
            try await symmetricKeyProvider.getSymmetricKey()
        }
    }

    public init(shareKeyRepository: any ShareKeyRepositoryProtocol,
                itemKeyDatasource: any RemoteItemKeyDatasourceProtocol,
                folderKeyDatasource: any LocalFolderKeyDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider) {
        self.shareKeyRepository = shareKeyRepository
        self.itemKeyDatasource = itemKeyDatasource
        self.userManager = userManager
        self.folderKeyDatasource = folderKeyDatasource
        logger = .init(manager: logManager)
        self.symmetricKeyProvider = symmetricKeyProvider
    }
}

// MARK: - Public API

public extension PassKeyManager {
    func getShareKey(userId: String,
                     shareId: String,
                     keyRotation: Int64) async throws -> any CryptographicKeyProtocol {
        try await loadKeysIfNeeded()

        // Check cache first with correct rotation
        if let cachedKey = getCachedKey(id: shareId, keyRotation: keyRotation) {
            return cachedKey
        }

        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId, shareId: shareId)
        guard let encryptedShareKey = allEncryptedShareKeys.first(where: { $0.keyRotation == keyRotation }) else {
            throw PassError.keysNotFound(shareID: shareId)
        }

        return try await symmetricDecryptAndCache(encryptedShareKey)
    }

    func getLatestShareKey(userId: String, shareId: String) async throws -> any CryptographicKeyProtocol {
        try await loadKeysIfNeeded()

        // Check cache first for latest
        if let cachedKey = getLatestCachedKey(id: shareId) {
            return cachedKey
        }

        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId, shareId: shareId)
        let latestShareKey = try allEncryptedShareKeys.latestKey()
        return try await symmetricDecryptAndCache(latestShareKey)
    }

    func getShareKeys(userId: String,
                      share: Share,
                      item: any ItemIdentifiable) async throws -> [any CryptographicKeyProtocol] {
        try await loadKeysIfNeeded()

        switch share.shareType {
        case .vault:
            return try await getItemKeys(userId: userId,
                                         shareId: item.shareId,
                                         parentId: item.parentId,
                                         itemId: item.itemId)

        case .item:
            let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId,
                                                                             shareId: item.shareId)
            return try await decryptAndCacheAll(allEncryptedShareKeys)

        case .unknown:
            throw PassError.unknownShareType
        }
    }

    func getLatestItemKey(userId: String,
                          shareId: String,
                          parentId: String,
                          itemId: String) async throws -> any CryptographicKeyProtocol {
        try await loadKeysIfNeeded()

        let keyDescription = "shareId \"\(shareId)\", itemId: \"\(itemId)\""
        logger.trace("Getting latest item key \(keyDescription)")

        let latestItemKey = try await itemKeyDatasource.getLatestKey(userId: userId,
                                                                     shareId: shareId,
                                                                     itemId: itemId)

        logger.trace("Decrypting latest item key \(keyDescription)")
        let decryptedItemKey = try decryptItemKey(latestItemKey, parentId: parentId, itemId: itemId)
        logger.trace("Decrypted latest item key \(keyDescription)")

        return decryptedItemKey
    }

    func getItemKeys(userId: String,
                     shareId: String,
                     parentId: String,
                     itemId: String) async throws -> [any CryptographicKeyProtocol] {
        try await loadKeysIfNeeded()

        logger.trace("Getting all item keys itemId \(itemId), share \(shareId)")
        let encryptedKeys = try await itemKeyDatasource.getAllKeys(userId: userId,
                                                                   shareId: shareId,
                                                                   itemId: itemId)

        logger.trace("Decrypting \(encryptedKeys.count) item keys itemId \(itemId), shareId \(shareId)")

        let decryptedKeys = try encryptedKeys.map { encryptedKey in
            try decryptItemKey(encryptedKey, parentId: parentId, itemId: itemId)
        }

        logger.trace("Decrypted \(encryptedKeys.count) item keys itemId \(itemId), shareId \(shareId)")
        return decryptedKeys
    }

    func getItemKey(userId: String,
                    shareId: String,
                    parentId: String,
                    itemId: String,
                    keyRotation: Int64) async throws -> any CryptographicKeyProtocol {
        try await loadKeysIfNeeded()

        // Try to get just the specific key if datasource supports it
        let encryptedKeys = try await itemKeyDatasource.getAllKeys(userId: userId,
                                                                   shareId: shareId,
                                                                   itemId: itemId)

        guard let encryptedKey = encryptedKeys.first(where: { $0.keyRotation == keyRotation }) else {
            throw PassError.keysNotFound(shareID: shareId)
        }

        return try decryptItemKey(encryptedKey, parentId: parentId, itemId: itemId)
    }

    func getContainerKey(containerId: String,
                         keyRotation: Int64? = nil) async throws -> any CryptographicKeyProtocol {
        try await loadKeysIfNeeded()
        return try await getContainerKey(containerId: containerId, keyRotation: keyRotation, refreshed: false)
    }

    func decryptAndStoreFolderKeys(shareId: String, folders: [Folder]) async throws {
        guard !folders.isEmpty else { return }
        let userId = try await userManager.getActiveUserId()

        let shareKey: any CryptographicKeyProtocol
        if let cachedKey = getLatestCachedKey(id: shareId) {
            shareKey = cachedKey
        } else {
            try await refreshShareKeys(shareId: shareId)
            guard let refreshedKey = getLatestCachedKey(id: shareId) else {
                throw PassError.keysNotFound(shareID: shareId)
            }
            shareKey = refreshedKey
        }

        // Build adjacency map for O(1) child lookup
        let adjacencyMap = Dictionary(grouping: folders, by: \.parentFolderID)
        let batchFolderIds = Set(folders.map(\.id))

        // Find batch roots: folders with no parent OR parent not in this batch
        let batchRoots = folders.filter { folder in
            guard let parentId = folder.parentFolderID else { return true }
            return !batchFolderIds.contains(parentId)
        }

        let keysToBeSaved = try await withThrowingTaskGroup(of: [DecryptedFolderKey].self) { [weak self] group in
            guard let self else { throw PassError.deallocatedSelf }

            for root in batchRoots {
                group.addTask {
                    let startKey: any CryptographicKeyProtocol

                    if let parentId = root.parentFolderID {
                        let fullParentId = parentId + shareId
                        guard let cachedKey = await self.getLatestCachedKey(id: fullParentId) else {
                            throw PassError.crypto(.missingKeys)
                        }
                        startKey = cachedKey
                    } else {
                        startKey = shareKey
                    }

                    return try await self.processNode(shareId: shareId,
                                                      folder: root,
                                                      parentKey: startKey,
                                                      adjacencyMap: adjacencyMap)
                }
            }

            var allDecryptedFolders = [DecryptedFolderKey]()
            for try await treeResult in group {
                allDecryptedFolders.append(contentsOf: treeResult)
            }

            return allDecryptedFolders
        }

        try await saveFolderKeys(userId: userId, shareId: shareId, keysToBeSaved)
    }
}

// MARK: - Private Helpers

private extension PassKeyManager {
    /// Guarded variant that prevents infinite recursion: refreshes remote keys at most once.
    func getContainerKey(containerId: String,
                         keyRotation: Int64?,
                         refreshed: Bool) async throws -> any CryptographicKeyProtocol {
        let key: (any CryptographicKeyProtocol)? = if let keyRotation {
            getCachedKey(id: containerId, keyRotation: keyRotation)
        } else {
            getLatestCachedKey(id: containerId)
        }

        if let key { return key }

        guard !refreshed else {
            throw PassError.keysNotFound(shareID: containerId)
        }

        try await refreshShareKeys(shareId: containerId)
        return try await getContainerKey(containerId: containerId, keyRotation: keyRotation, refreshed: true)
    }

    func symmetricDecryptAndCache(_ encryptedKey: SymmetricallyEncryptedKeyProtocol) async throws
        -> any CryptographicKeyProtocol {
        let containerId = encryptedKey.id
        let keyRotation = encryptedKey.keyRotation
        let keyDescription = "Container id \(containerId), keyRotation: \(keyRotation)"

        logger.trace("Decrypting container key \(keyDescription)")

        let decryptedContainerKey = try await encryptedKey.decrypt(with: symmetricKey)

        cacheKey(decryptedContainerKey, id: containerId)

        logger.info("Decrypted & cached container key \(keyDescription)")
        return decryptedContainerKey
    }

    func decryptAndCacheAll(_ encryptedKeys: [SymmetricallyEncryptedKeyProtocol]) async throws
        -> [any CryptographicKeyProtocol] {
        var decryptedKeys = [any CryptographicKeyProtocol]()
        decryptedKeys.reserveCapacity(encryptedKeys.count)

        for encryptedKey in encryptedKeys {
            let decryptedKey = try await symmetricDecryptAndCache(encryptedKey)
            decryptedKeys.append(decryptedKey)
        }

        return decryptedKeys
    }

    func decryptItemKey(_ itemKey: ItemKey,
                        parentId: String,
                        itemId: String) throws -> DecryptedItemKey {
        guard let parentKey = getCachedKey(id: parentId, keyRotation: itemKey.keyRotation) else {
            throw PassError.keysNotFound(shareID: parentId)
        }

        guard let encryptedItemKeyData = try itemKey.key.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedItemKeyData,
                                                    key: parentKey.keyData,
                                                    associatedData: .itemKey)

        return DecryptedItemKey(containerId: parentId,
                                itemId: itemId,
                                keyRotation: itemKey.keyRotation,
                                keyData: decryptedItemKeyData)
    }

    func decryptFolderKey(shareId: String,
                          folder: Folder,
                          parentKey: any CryptographicKeyProtocol) throws -> DecryptedFolderKey {
        guard let encryptedFolderKeyData = try folder.folderKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedKeyData = try AES.GCM.open(encryptedFolderKeyData,
                                                key: parentKey.keyData,
                                                associatedData: .folderKey)

        return DecryptedFolderKey(shareId: shareId,
                                  folderId: folder.folderID,
                                  keyRotation: folder.keyRotation,
                                  keyData: decryptedKeyData)
    }

    func processNode(shareId: String,
                     folder: Folder,
                     parentKey: any CryptographicKeyProtocol,
                     adjacencyMap: [String?: [Folder]]) async throws -> [DecryptedFolderKey] {
        let currentDecryptedKey = try decryptFolderKey(shareId: shareId, folder: folder, parentKey: parentKey)
        let uniqueFolderId = folder.id + shareId
        cacheKey(currentDecryptedKey, id: uniqueFolderId)

        guard let children = adjacencyMap[folder.id], !children.isEmpty else {
            return [currentDecryptedKey]
        }

        return try await withThrowingTaskGroup(of: [DecryptedFolderKey].self) { group in
            for child in children {
                group.addTask {
                    try await self.processNode(shareId: shareId,
                                               folder: child,
                                               parentKey: currentDecryptedKey,
                                               adjacencyMap: adjacencyMap)
                }
            }

            var subtreeResults = [currentDecryptedKey]
            for try await childSubtree in group {
                subtreeResults.append(contentsOf: childSubtree)
            }

            return subtreeResults
        }
    }

    func saveFolderKeys(userId: String, shareId: String, _ keys: [DecryptedFolderKey]) async throws {
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()

        let encryptedKeys: [SymmetricallyEncryptedFolderKey] = try keys.map { key in
            let encryptedKeyBase64 = key.keyData.encodeBase64()
            let symmetricallyEncryptedKey = try symmetricKey.encrypt(encryptedKeyBase64)
            return SymmetricallyEncryptedFolderKey(shareId: shareId,
                                                   encryptedKey: symmetricallyEncryptedKey,
                                                   folderId: key.folderId,
                                                   userId: userId,
                                                   keyRotation: key.keyRotation)
        }

        try await folderKeyDatasource.upsertFolderKeys(encryptedKeys)
    }
}

// MARK: - Cache Helpers

private extension PassKeyManager {
    func getCachedKey(id: String, keyRotation: Int64) -> (any CryptographicKeyProtocol)? {
        keyCache[id]?[keyRotation]
    }

    func getLatestCachedKey(id: String) -> (any CryptographicKeyProtocol)? {
        guard let rotations = keyCache[id],
              let maxRotation = rotations.keys.max() else {
            return nil
        }
        return rotations[maxRotation]
    }

    func cacheKey(_ key: any CryptographicKeyProtocol, id: String) {
        keyCache[id, default: [:]][key.keyRotation] = key
    }
}

// MARK: - Key Loading

private extension PassKeyManager {
    func loadKeysIfNeeded() async throws {
        if keysLoaded { return }

        // Prevent concurrent loading - reuse existing task if in progress
        if let existingTask = loadingTask {
            try await existingTask.value
            return
        }

        // Create task that calls back into actor-isolated method
        let task = Task { [weak self] in
            guard let self else { throw PassError.deallocatedSelf }
            try await performKeysLoading()
        }

        loadingTask = task

        do {
            try await task.value
            loadingTask = nil
        } catch {
            loadingTask = nil
            logger.error(error)
            throw error
        }
    }

    func performKeysLoading() async throws {
        async let shareKeysRequest = shareKeyRepository.getAllLocalKeys()
        async let folderKeysRequest = folderKeyDatasource.getAllFolderKeys()
        let (shareKeys, folderKeys) = try await (shareKeysRequest, folderKeysRequest)

        let symmetricKey = try await symmetricKey

        for key in shareKeys {
            let decryptedKey = try key.decrypt(with: symmetricKey)
            cacheKey(decryptedKey, id: key.id)
        }

        for key in folderKeys {
            let decryptedKey = try key.decrypt(with: symmetricKey)
            cacheKey(decryptedKey, id: key.id)
        }

        keysLoaded = true
    }

    func refreshShareKeys(shareId: String) async throws {
        let userId = try await userManager.getActiveUserId()
        let refreshedKeys = try await shareKeyRepository.refreshKeys(userId: userId, shareId: shareId)

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for encryptedShareKey in refreshedKeys {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    _ = try await symmetricDecryptAndCache(encryptedShareKey)
                }
            }
            try await taskGroup.waitForAll()
        }
    }
}

private extension SymmetricallyEncryptedKeyProtocol {
    func decrypt(with encryptionKey: SymmetricKey) throws -> any CryptographicKeyProtocol {
        let decryptedKey = try encryptionKey.decrypt(encryptedKey)
        guard let decryptedKeyData = try decryptedKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }
        return buildKey(with: decryptedKeyData)
    }
}
