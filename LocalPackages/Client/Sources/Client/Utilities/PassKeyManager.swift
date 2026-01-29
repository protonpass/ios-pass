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

import Collections
import Core
@preconcurrency import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin

public protocol CryptographicKeyProtocol: Hashable, Sendable {
    var keyRotation: Int64 { get }
    var keyData: Data { get }
}

public struct DecryptedShareKey: CryptographicKeyProtocol {
    let shareId: String
    public let keyRotation: Int64
    public let keyData: Data

    public init(shareId: String, keyRotation: Int64, keyData: Data) {
        self.shareId = shareId
        self.keyRotation = keyRotation
        self.keyData = keyData
    }
}

// TODO: maybe cahnge naming of sahre id for parent id
public struct DecryptedItemKey: CryptographicKeyProtocol {
    let shareId: String
    let itemId: String
    public let keyRotation: Int64
    public let keyData: Data

    public init(shareId: String, itemId: String, keyRotation: Int64, keyData: Data) {
        self.shareId = shareId
        self.itemId = itemId
        self.keyRotation = keyRotation
        self.keyData = keyData
    }
}

public struct DecryptedFolderKey: CryptographicKeyProtocol {
    public let folderId: String
    public let keyRotation: Int64
    public let keyData: Data

    public init(folderId: String, keyRotation: Int64, keyData: Data) {
        self.folderId = folderId
        self.keyRotation = keyRotation
        self.keyData = keyData
    }
}

// sourcery: AutoMockable
public protocol PassKeyManagerProtocol: Sendable, AnyObject {
    /// Get share key of a given key rotation to decrypt share content
    func getShareKey(userId: String,
                     shareId: String,
                     keyRotation: Int64) async throws -> any CryptographicKeyProtocol

    /// Get share key with latest rotation
    func getLatestShareKey(userId: String, shareId: String) async throws -> any CryptographicKeyProtocol

    /// Get all share keys
    func getShareKeys(userId: String,
                      share: Share,
                      item: any FullItemIdentifiable) async throws -> [any CryptographicKeyProtocol]

    func getLatestItemKey(userId: String,
                          shareId: String,
                          containerId: String,
                          itemId: String) async throws -> any CryptographicKeyProtocol
    /// Get all decrypted item keys
    func getItemKeys(userId: String,
                     shareId: String,
                     containerId: String,
                     itemId: String) async throws -> [any CryptographicKeyProtocol]

    func getItemKey(userId: String,
                    shareId: String,
                    containerId: String,
                    itemId: String,
                    keyRotation: Int64) async throws -> any CryptographicKeyProtocol

    func decryptAndStoreFolderKeys(shareId: String, folders: [Folder]) async throws
    func getDecryptionKey(userId: String,
                          containerId: String) async throws -> any CryptographicKeyProtocol
}

extension SymmetricallyEncryptedShareKey: SymmetricallyEncryptedKeyType {
    var id: String {
        shareId
    }

    var keyRotation: Int64 {
        shareKey.keyRotation
    }

    func buildKey(with decryptedKeyData: Data) -> any CryptographicKeyProtocol {
        DecryptedShareKey(shareId: shareId,
                          keyRotation: shareKey.keyRotation,
                          keyData: decryptedKeyData)
    }
}

extension SymmetricallyEncryptedFolderKey: SymmetricallyEncryptedKeyType {
    var id: String {
        folderId
    }

    func buildKey(with decryptedKeyData: Data) -> any CryptographicKeyProtocol {
        DecryptedFolderKey(folderId: folderId,
                           keyRotation: keyRotation,
                           keyData: decryptedKeyData)
    }
}

protocol SymmetricallyEncryptedKeyType {
    var id: String { get }
    var keyRotation: Int64 { get }
    var encryptedKey: String { get }

    func buildKey(with decryptedKeyData: Data) -> any CryptographicKeyProtocol
}

struct KeyIdentifier: Hashable {
    let id: String
    let keyRotation: Int64
}

public actor PassKeyManager: PassKeyManagerProtocol {
    // This contains the current keys of share and folder used to decrypt item keys and content
    // The key should maybe contain id + keyrotation for the futur
    private var cachedContainerKeys = [String: any CryptographicKeyProtocol]()

    private let userManager: any UserManagerProtocol
    private let shareKeyRepository: any ShareKeyRepositoryProtocol
    private let itemKeyDatasource: any RemoteItemKeyDatasourceProtocol
    private let folderKeyDatasource: any LocalFolderKeyDatasourceProtocol

    private let logger: Logger
    private let symmetricKeyProvider: any SymmetricKeyProvider

    // Performance tracking
    private var processedCount = 0
    private let maxLevels = 5

    private var keysLoaded = false
    private var loadingTask: Task<Void, Never>?

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

    private func loadKeysIfNeeded() async {
        guard !keysLoaded else {
            return
        }

        do {
            async let shareKeysRequest = shareKeyRepository.getAllLocalKeys()
            async let folderKeysRequest = folderKeyDatasource.getAllFolderKeys()
            let (shareKeys, folderKeys) = try await (shareKeysRequest, folderKeysRequest)
            let allKeys: [SymmetricallyEncryptedKeyType] = shareKeys + folderKeys

            for key in allKeys {
                let decryptedKey = try await symmetricKeyProvider.getSymmetricKey().decrypt(key.encryptedKey)
                guard let decryptedKeyData = try decryptedKey.base64Decode() else {
                    throw PassError.crypto(.failedToBase64Decode)
                }
                let decryptedContainerKey = key.buildKey(with: decryptedKeyData)
                cachedContainerKeys[key.id] = decryptedContainerKey
            }
            keysLoaded = true
        } catch {
            logger.error(error)
        }
    }
}

public extension PassKeyManager {
    func getShareKey(userId: String,
                     shareId: String,
                     keyRotation: Int64) async throws -> any CryptographicKeyProtocol {
        // ⚠️ Do not add logs to this function because it's supposed to be called all the time
        // when decrypting items. As IO operations caused by the log system take time
        // this will slow down dramatically the decryping process
//        if let cachedKey = decryptedShareKeys.first(where: {
//            $0.shareId == shareId && $0.keyRotation == keyRotation
//        }) {
//            return cachedKey
//        }

        if let cachedKey = cachedContainerKeys[shareId] {
            return cachedKey
        }
        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId, shareId: shareId)
        guard let encryptedShareKey = allEncryptedShareKeys.first(where: { $0.shareId == shareId }) else {
            throw PassError.keysNotFound(shareID: shareId)
        }
        return try await symmetricDecryptAndCache(encryptedShareKey, containerId: shareId)
    }

    func getLatestShareKey(userId: String, shareId: String) async throws -> any CryptographicKeyProtocol {
        // TODO: why not check if it is already cached ?
        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId, shareId: shareId)
        let latestShareKey = try allEncryptedShareKeys.latestKey()
        return try await symmetricDecryptAndCache(latestShareKey, containerId: shareId)
    }

    func getShareKeys(userId: String,
                      share: Share,
                      item: any FullItemIdentifiable) async throws -> [any CryptographicKeyProtocol] {
        switch share.shareType {
        case .vault:
            return try await getItemKeys(userId: userId,
                                         shareId: item.shareId,
                                         containerId: item.item.folderID ?? item.shareId,
                                         itemId: item.item.itemID)

        case .item:
            let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId,
                                                                             shareId: item.shareId)

            var decryptedKeys = [any CryptographicKeyProtocol]()
            for encryptedKey in allEncryptedShareKeys {
                let decryptedKey = try await symmetricDecryptAndCache(encryptedKey, containerId: share.id)
                decryptedKeys.append(decryptedKey)
            }
            return decryptedKeys

        case .unknown:
            throw PassError.unknownShareType
        }
    }

    func getLatestItemKey(userId: String,
                          shareId: String,
                          containerId: String,
                          itemId: String) async throws -> any CryptographicKeyProtocol {
        await loadKeysIfNeeded()
        let keyDescription = "shareId \"\(shareId)\", itemId: \"\(itemId)\""
        logger.trace("Getting latest item key \(keyDescription)")
        let latestItemKey = try await itemKeyDatasource.getLatestKey(userId: userId,
                                                                     shareId: shareId,
                                                                     itemId: itemId)

        logger.trace("Decrypting latest item key \(keyDescription)")
        let decryptedItemKey = try await decrypt(itemKey: latestItemKey,
                                                 userId: userId,
                                                 parentId: containerId,
                                                 itemId: itemId)
        logger.trace("Decrypted latest item key \(keyDescription)")
        return decryptedItemKey
    }

    func getItemKeys(userId: String,
                     shareId: String,
                     containerId: String,
                     itemId: String) async throws -> [any CryptographicKeyProtocol] {
        logger.trace("Getting all item keys itemId \(itemId), share \(shareId)")
        let encryptedKeys = try await itemKeyDatasource.getAllKeys(userId: userId,
                                                                   shareId: shareId,
                                                                   itemId: itemId)
        logger.trace("Decrypting \(encryptedKeys.count) item keys itemId \(itemId), shareId \(shareId)")
        var decryptedKeys = [DecryptedItemKey]()
        for encryptedKey in encryptedKeys {
            let decryptedKey = try await decrypt(itemKey: encryptedKey,
                                                 userId: userId,
                                                 parentId: containerId,
                                                 itemId: itemId)
            decryptedKeys.append(decryptedKey)
        }
        logger.trace("Decrypted \(encryptedKeys.count) item keys itemId \(itemId), shareId \(shareId)")
        return decryptedKeys
    }

    // This need to take and item to have info of share or folder or shareId must be repalce by parent id
    func getItemKey(userId: String,
                    shareId: String,
                    containerId: String,
                    itemId: String,
                    keyRotation: Int64) async throws -> any CryptographicKeyProtocol {
        guard let key = try await getItemKeys(userId: userId,
                                              shareId: shareId,
                                              containerId: containerId,
                                              itemId: itemId)
            .first(where: { $0.keyRotation == keyRotation }) else {
            throw PassError.keysNotFound(shareID: shareId)
        }
        return key
    }

    func getDecryptionKey(userId: String,
                          containerId: String) async throws -> any CryptographicKeyProtocol {
        if !keysLoaded {
            await loadKeysIfNeeded()
        }
        guard let key = cachedContainerKeys[containerId] else {
            throw PassError.keysNotFound(shareID: containerId)
        }

        return key
    }

    // 3. THE DECRYPTION LOGIC

    /// Main entry point
    func decryptAndStoreFolderKeys(shareId: String, folders: [Folder]) async throws {
        guard !folders.isEmpty, let shareKey = cachedContainerKeys[shareId] else {
            return
        }
        let userId = try await userManager.getActiveUserId()
        // PRE-PROCESSING: O(N)
        // Group folders by their parentID for instant O(1) lookup later.
        // We use a Dictionary [Optional<String> : [Folder]]
        // 'nil' key will hold the Root folders.
        let adjacencyMap = Dictionary(grouping: folders, by: { $0.parentFolderID })

        // B. Create a Set of all IDs in this batch for O(1) existence checks
        let batchFolderIds = Set(folders.map(\.id))

        // C. Identify "Batch Roots"
        // A folder is a starting point if:
        // 1. It has NO parent (True Root) OR
        // 2. Its parent is NOT in this current batch (Mid-tree update)
        let batchRoots = folders.filter { folder in
            guard let pId = folder.parentFolderID else { return true } // Case 1
            return !batchFolderIds.contains(pId) // Case 2
        }

        // Use a TaskGroup to process independent trees in parallel
        let keysToBeSaved = try await withThrowingTaskGroup(of: [DecryptedFolderKey].self) { [weak self] group in
            guard let self else {
                throw PassError.deallocatedSelf
            }

            for root in batchRoots {
                group.addTask {
                    // Determine the correct key to start with
                    let startKey: any CryptographicKeyProtocol

                    if let pId = root.parentFolderID {
                        // It's a mid-tree update. We MUST find the key in cache.
                        guard let cachedKey = await self.cachedContainerKeys[pId] else {
                            throw PassError.crypto(.missingKeys)
                        }
                        startKey = cachedKey
                    } else {
                        // It's a true root. Use the Vault Key.
                        startKey = shareKey
                    }

                    // Start the recursive processing for this tree/subtree
                    return try await self.processNode(folder: root,
                                                      parentKey: startKey,
                                                      adjacencyMap: adjacencyMap)
                }
            }

            // Collect results from all trees into a single flat array
            var allDecryptedFolders: [DecryptedFolderKey] = []
            for try await treeResult in group {
                allDecryptedFolders.append(contentsOf: treeResult)
            }

            return allDecryptedFolders
        }
        try await saveFolderKeys(userId: userId, keysToBeSaved)
    }

    func decrypt(folder: Folder,
                 parentKey: any CryptographicKeyProtocol) throws -> DecryptedFolderKey {
        guard let encryptedFolderKeyData = try folder.folderKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedFolderKeyData,
                                                    key: parentKey.keyData,
                                                    associatedData: .folderKey)

        return DecryptedFolderKey(folderId: folder.folderID,
                                  keyRotation: folder.keyRotation,
                                  keyData: decryptedItemKeyData)
    }

    /// Recursive function that handles:
    /// 1. Decrypting the current node
    /// 2. Spawning parallel tasks for all children
    private func processNode(folder: Folder,
                             parentKey: any CryptographicKeyProtocol,
                             adjacencyMap: [String?: [Folder]]) async throws -> [DecryptedFolderKey] {
        // A. Decrypt current folder (Wait for this before children start)
        let currentDecryptedKey = try decrypt(folder: folder, parentKey: parentKey)

        cachedContainerKeys[folder.id] = currentDecryptedKey

        // B. Check for children
        guard let children = adjacencyMap[folder.id], !children.isEmpty else {
            // Leaf node: return just itself
            return [currentDecryptedKey]
        }

        // C. Parallel Execution for Children
        // We create a nested TaskGroup so all siblings decrypt simultaneously
        return try await withThrowingTaskGroup(of: [DecryptedFolderKey].self) { group in
            for child in children {
                group.addTask {
                    // Recursion: Pass the NEW key down
                    try await self.processNode(folder: child,
                                               parentKey: currentDecryptedKey,
                                               adjacencyMap: adjacencyMap)
                }
            }

            // Start with the parent (current node)
            var subtreeResults = [currentDecryptedKey]

            // Append all children (and their children) as they finish
            for try await childSubtree in group {
                subtreeResults.append(contentsOf: childSubtree)
            }

            return subtreeResults
        }
    }

    func saveFolderKeys(userId: String, _ keys: [DecryptedFolderKey]) async throws {
        let encryptedKeys: [SymmetricallyEncryptedFolderKey] = try await keys.asyncCompactMap { key in
            let encryptedKeyBase64 = key.keyData.encodeBase64()
            let symmetricallyEncryptedKey = try await symmetricKeyProvider.getSymmetricKey()
                .encrypt(encryptedKeyBase64)
            return SymmetricallyEncryptedFolderKey(encryptedKey: symmetricallyEncryptedKey,
                                                   folderId: key.folderId,
                                                   userId: userId,
                                                   keyRotation: key.keyRotation)
        }

        try await folderKeyDatasource.upsertFolderKeys(encryptedKeys)
    }
}

private extension PassKeyManager {
    func symmetricDecryptAndCache(_ encryptedKey: SymmetricallyEncryptedKeyType, containerId: String?) async throws
        -> any CryptographicKeyProtocol {
        let containerId = containerId ?? encryptedKey.id
        let keyRotation = encryptedKey.keyRotation
        let keyDescription = "Container id \(containerId), keyRotation: \(keyRotation)"
        logger.trace("Decrypting container key \(keyDescription)")

        let decryptedKey = try await symmetricKeyProvider.getSymmetricKey().decrypt(encryptedKey.encryptedKey)
        guard let decryptedKeyData = try decryptedKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }
        let decryptedContainerKey = encryptedKey.buildKey(with: decryptedKeyData)
        cachedContainerKeys[containerId] = decryptedContainerKey

        logger.info("Decrypted & cached share key share \(keyDescription)")
        return decryptedContainerKey
    }

    func decrypt(itemKey: ItemKey,
                 userId: String,
                 shareId: String,
                 itemId: String) async throws -> DecryptedItemKey {
        // TODO: parent keys
        let vaultKey = try await getShareKey(userId: userId,
                                             shareId: shareId,
                                             keyRotation: itemKey.keyRotation)

        guard let encryptedItemKeyData = try itemKey.key.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedItemKeyData,
                                                    key: vaultKey.keyData,
                                                    associatedData: .itemKey)

        return .init(shareId: shareId,
                     itemId: itemId,
                     keyRotation: itemKey.keyRotation,
                     keyData: decryptedItemKeyData)
    }

    func decrypt(itemKey: ItemKey,
                 userId: String,
                 parentId: String,
                 itemId: String) async throws -> DecryptedItemKey {
        guard let parentKey = cachedContainerKeys[parentId] else {
            throw PassError.keysNotFound(shareID: parentId)
        }

        guard let encryptedItemKeyData = try itemKey.key.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedItemKeyData,
                                                    key: parentKey.keyData,
                                                    associatedData: .itemKey)

        return .init(shareId: parentId,
                     itemId: itemId,
                     keyRotation: itemKey.keyRotation,
                     keyData: decryptedItemKeyData)
    }

    func decrypt(folder: Folder,
                 shareId: String,
                 parentKey: any CryptographicKeyProtocol) throws -> DecryptedFolderKey {
        guard let encryptedFolderKeyData = try folder.folderKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(encryptedFolderKeyData,
                                                    key: parentKey.keyData,
                                                    associatedData: .folderKey)

        return DecryptedFolderKey(folderId: folder.folderID,
                                  keyRotation: folder.keyRotation,
                                  keyData: decryptedItemKeyData)
    }
}
