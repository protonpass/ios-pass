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
    public let shareId: String
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
    public let shareId: String
    public let itemId: String
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
//    func getShareKeys(userId: String,
//                      share: Share,
//                      item: any ItemIdentifiable) async throws -> [any CryptographicKeyProtocol]
    func getShareKeys(userId: String,
                      share: Share,
                      item: any FullItemIdentifiable) async throws -> [any CryptographicKeyProtocol]

    /// Get the latest key of an item to encrypt item content
    // TODO: need parent id and not share id anymore
//    func getLatestItemKey(userId: String,
//                          shareId: String,
//                          itemId: String) async throws -> any CryptographicKeyProtocol
//
//    /// Get all decrypted item keys
//    func getItemKeys(userId: String,
//                     shareId: String,
//                     itemId: String) async throws -> [any CryptographicKeyProtocol]
//
//    func getItemKey(userId: String,
//                    shareId: String,
//                    itemId: String,
//                    keyRotation: Int64) async throws -> any CryptographicKeyProtocol

//        func getItemKeys(userId: String,
//                        shareId: String,
//                        containerId: String,
//                        itemId: String,
//                        keyRotation: Int64) async throws -> any CryptographicKeyProtocol

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

//    func getFolderKeys(userId: String, parentId: String, folderId: String) async throws -> [any
//    DecryptionKeyProtocol]

//    /// Get the parent decryption key of and element. the parent id can either be a share id or a folder id
//    func getDecryptionKey(userId: String, parentId: String, keyRotation: Int) async throws -> any
//    DecryptionKeyProtocol
//
    // TODO: Folder KEy
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
    ////    case share(SymmetricallyEncryptedShareKey)
    ////    case folder(SymmetricallyEncryptedFolderKey)
    ////
    ////    var id: String {
    ////        switch self {
    ////        case let.share(key):
    ////            key.shareId
    ////        case let .folder(key):
    ////            key.folderId
    ////        }
    ////    }
    ////
    ////    var keyRotation: Int64 {
    ////        switch self {
    ////        case let.share(key):
    ////            key.shareKey.keyRotation
    ////        case let .folder(key):
    ////            key.keyRotation
    ////        }
    ////    }
}

struct KeyIdentifier: Hashable {
    let id: String
    let keyRotation: Int64
}

public actor PassKeyManager: PassKeyManagerProtocol {
    // This contains the current keys of share and folder used to decrypt item keys and content
    // The key should maybe contain id + keyrotation for the futur
    private var cachedContainerKeys = [String: any CryptographicKeyProtocol]()

//    private var decryptedShareKeys = Set<DecryptedShareKey>()
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

//        loadKeysIfNeeded()
        // TODO: pull all local share and folder key into cache
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
    // TODO: func load all local keys to cache as know we have share + folder keys
}

public extension PassKeyManager {
    // TODO: must be private
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
        return try await symmetricDecryptAndCache(encryptedShareKey)
    }

    func getLatestShareKey(userId: String, shareId: String) async throws -> any CryptographicKeyProtocol {
        // TODO: why not check if it is already cached ?
        let allEncryptedShareKeys = try await shareKeyRepository.getKeys(userId: userId, shareId: shareId)
        let latestShareKey = try allEncryptedShareKeys.latestKey()
        return try await symmetricDecryptAndCache(latestShareKey)
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
                let decryptedKey = try await symmetricDecryptAndCache(encryptedKey)
                decryptedKeys.append(decryptedKey)
            }
            return decryptedKeys

        case .unknown:
            throw PassError.unknownShareType
        }
    }

//    //This need to take and item to have info of share or folder or shareId must be repalce by parent id
//    private func getLatestItemKey(userId: String,
//                          shareId: String,
//                          itemId: String) async throws -> any CryptographicKeyProtocol {
//        let keyDescription = "shareId \"\(shareId)\", itemId: \"\(itemId)\""
//        logger.trace("Getting latest item key \(keyDescription)")
//        let latestItemKey = try await itemKeyDatasource.getLatestKey(userId: userId,
//                                                                     shareId: shareId,
//                                                                     itemId: itemId)
//
//        logger.trace("Decrypting latest item key \(keyDescription)")
//        let decryptedItemKey = try await decrypt(itemKey: latestItemKey,
//                                                 userId: userId,
//                                                 shareId: shareId,
//                                                 itemId: itemId)
//        logger.trace("Decrypted latest item key \(keyDescription)")
//        return decryptedItemKey
//    }

    func getLatestItemKey(userId: String,
                          shareId: String,
                          containerId: String,
                          itemId: String) async throws -> any CryptographicKeyProtocol {
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

//
//    //This need to take and item to have info of share or folder or shareId must be repalce by parent id
//    private func getItemKeys(userId: String,
//                     shareId: String,
//                     itemId: String) async throws -> [any CryptographicKeyProtocol] {
//        logger.trace("Getting all item keys itemId \(itemId), shareId \(shareId)")
//        let encryptedKeys = try await itemKeyDatasource.getAllKeys(userId: userId,
//                                                                   shareId: shareId,
//                                                                   itemId: itemId)
//        logger.trace("Decrypting \(encryptedKeys.count) item keys itemId \(itemId), shareId \(shareId)")
//        var decryptedKeys = [DecryptedItemKey]()
//        for encryptedKey in encryptedKeys {
//            let decryptedKey = try await decrypt(itemKey: encryptedKey,
//                                                 userId: userId,
//                                                 shareId: shareId,
//                                                 itemId: itemId)
//            decryptedKeys.append(decryptedKey)
//        }
//        logger.trace("Decrypted \(encryptedKeys.count) item keys itemId \(itemId), shareId \(shareId)")
//        return decryptedKeys
//    }

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

    // TODO: decrypt folder keys and store the keys in data base
    func decryptAndStoreFolderKeys(shareId: String, folders: [Folder]) async throws {
        // Build lookup structures - O(N) initialization
        var folderMap: [String: Folder] = [:]
        var childrenMap: [String: [String]] = [:]

        let userId = try await userManager.getActiveUserId()
        for folder in folders {
            folderMap[folder.id] = folder

            if let parentId = folder.parentFolderID {
                childrenMap[parentId, default: []].append(folder.id)
            }
        }
        let startTime = CFAbsoluteTimeGetCurrent()

        // Step 1: Identify starting points (explicit or implicit roots)
        let startingFolders = try await identifyStartingPoints(shareId: shareId,
                                                               folders: folders,
                                                               folderMap: folderMap)
        guard !startingFolders.isEmpty else {
            throw PassError.unexpectedError
//            throw DecryptionError.noStartingPoint(
//                message: "No root folders found and no parent keys available for any folder"
//            )
        }

        print("Starting decryption with \(startingFolders.count) starting points")

        // Step 2: Initialize BFS queue with starting points
        var queue = Deque(startingFolders)
        var results: [String: any CryptographicKeyProtocol] = [:]
        var currentLevel = 0
        var keysToBeSaved = [DecryptedFolderKey]()

        // Step 3: BFS traversal with parallel level processing
        while !queue.isEmpty, currentLevel < maxLevels {
            let levelFolderIds = gatherCurrentLevelFolders(from: &queue)

            // Performance: Decrypt all folders at this level in parallel
            if let levelResults = try await decryptLevel(userId: userId,
                                                         shareId: shareId,
                                                         levelFolders: levelFolderIds,
                                                         folderMap: folderMap) as? [DecryptedFolderKey] {
                keysToBeSaved.append(contentsOf: levelResults)
                // Store results and update state
                for result in levelResults {
                    results[result.folderId] = result
                    cachedContainerKeys[result.folderId] = result
                    processedCount += 1

                    // Enqueue children for next level
                    if let children = childrenMap[result.folderId] {
                        queue.append(contentsOf: children)
                    }
                }
            }
            currentLevel += 1
            print("Completed level \(currentLevel), processed \(processedCount) folders")
        }
        try await saveFolderKeys(userId: userId, keysToBeSaved)
//        // Step 4: Handle any remaining folders (orphaned or in cycles)
//        try await handleRemainingFolders(&results)

        let endTime = CFAbsoluteTimeGetCurrent()
        print("Total decryption time: \(String(format: "%.3f", endTime - startTime))s")
        print("Successfully decrypted \(results.count)/\(folders.count) folders")

//        return results
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

// MARK: - Folder utils

private extension PassKeyManager {
    // MARK: - Core Algorithm: Identify Starting Points

    private func identifyStartingPoints(shareId: String,
                                        folders: [Folder],
                                        folderMap: [String: Folder]) async throws -> [String] {
        var startingPoints: [String] = []

        for folder in folders {
            // Case 1: Explicit root (no parent)
            if folder.parentFolderID == nil {
                startingPoints.append(folder.id)
                continue
            }

            // Case 2: Parent is not in current batch
            guard let parentId = folder.parentFolderID else { continue }

            if !folderMap.keys.contains(parentId) {
                // Check if we have parent's key from previous decryption
                if cachedContainerKeys[parentId] != nil {
                    startingPoints.append(folder.id)
                }
                // If we don't have the key, this folder cannot be decrypted yet
                // It will be handled in handleRemainingFolders()
            }
        }

        // Case 3: No explicit roots, find implicit roots (folders with minimal dependencies)
        if startingPoints.isEmpty {
            let implicitRoots = findImplicitRoots(folders: folders, folderMap: folderMap)
            if !implicitRoots.isEmpty {
                print("Found \(implicitRoots.count) implicit roots")
                startingPoints.append(contentsOf: implicitRoots)
            }
        }

        return startingPoints
    }

    // MARK: - Find Implicit Roots (Graph Analysis)

    private func findImplicitRoots(folders: [Folder], folderMap: [String: Folder]) -> [String] {
        // Build dependency graph
        var dependencies: [String: Set<String>] = [:]
        var dependents: [String: Set<String>] = [:]

        for folder in folders {
            guard let parentId = folder.parentFolderID else { continue }

            if folderMap.keys.contains(parentId) {
                // Parent is in current batch, add dependency
                dependencies[folder.id, default: []].insert(parentId)
                dependents[parentId, default: []].insert(folder.id)
            }
        }

        // Find folders with no dependencies within the current batch
        var implicitRoots: [String] = []

        for folder in folders {
            // Has no parent in current batch OR parent exists but we have its key
            let hasParentInBatch = folder.parentFolderID != nil && folderMap.keys.contains(folder.parentFolderID!)
            let hasParentKey = folder.parentFolderID.flatMap { cachedContainerKeys[$0] } != nil

            if !hasParentInBatch || hasParentKey {
                // Also check if it's part of a dependency cycle
                if !isInDependencyCycle(folder.id, dependencies: dependencies) {
                    implicitRoots.append(folder.id)
                }
            }
        }

        return implicitRoots
    }

    // MARK: - Cycle Detection

    private func isInDependencyCycle(_ folderId: String, dependencies: [String: Set<String>]) -> Bool {
        var visited: Set<String> = []
        var recursionStack: Set<String> = []

        func dfs(_ currentId: String) -> Bool {
            if recursionStack.contains(currentId) { return true }
            if visited.contains(currentId) { return false }

            visited.insert(currentId)
            recursionStack.insert(currentId)

            for dependent in dependencies[currentId] ?? [] {
                if dfs(dependent) { return true }
            }

            recursionStack.remove(currentId)
            return false
        }

        return dfs(folderId)
    }

    // MARK: - BFS Level Processing

    private func gatherCurrentLevelFolders(from queue: inout Deque<String>) -> [String] {
        // Performance: Process all folders at current BFS level
        var currentLevelIds: [String] = []

        while !queue.isEmpty {
            currentLevelIds.append(queue.removeFirst())
        }

        return currentLevelIds
    }

    private func decryptLevel(userId: String,
                              shareId: String,
                              levelFolders: [String],
                              folderMap: [String: Folder]) async throws -> [any CryptographicKeyProtocol] {
        try await withThrowingTaskGroup(of: (any CryptographicKeyProtocol).self,
                                        returning: [any CryptographicKeyProtocol]
                                            .self) { [weak self] taskGroup in
            guard let self else { throw PassError.deallocatedSelf }
            for folderId in levelFolders {
                taskGroup.addTask { [weak self] in
                    guard let self else {
                        throw PassError.deallocatedSelf
                    }
                    return try await decryptSingleFolder(userId: userId,
                                                         sharedId: shareId,
                                                         folderId: folderId,
                                                         folderMap: folderMap)
                }
            }
            var encryptedFolders = [any CryptographicKeyProtocol]()

            for try await symmetricallyEncryptedFolder in taskGroup {
                encryptedFolders.append(symmetricallyEncryptedFolder)
            }

            return encryptedFolders
        }
    }

    private func decryptSingleFolder(userId: String,
                                     sharedId: String,
                                     folderId: String,
                                     folderMap: [String: Folder]) async throws -> any CryptographicKeyProtocol {
        guard let folder = folderMap[folderId] else {
            throw PassError.unexpectedError
//            throw DecryptionError.folderNotFound(folderId)
        }

        let parentId = folder.parentFolderID ?? folder.id

        let parentKey = if let key = cachedContainerKeys[parentId] {
            key
        } else {
            if folder.parentFolderID == nil {
                try await getShareKey(userId: userId, shareId: sharedId, keyRotation: folder.keyRotation)
            } else {
                throw PassError.unexpectedError
            }
        }

//        if let parentId = folder.parentId {
//                   // Get key from storage (either from current batch or previous decryption)
//                   guard let key = folderKeys[parentId] else {
//                       throw DecryptionError.parentNotDecrypted(
//                           folderId: folderId,
//                           parentId: parentId
//                       )
//                   }
//                   parentKey = key
//               } else {
//                   // Root folder - use vault key
//                   parentKey = try await vaultKeyProvider.getVaultKey()
//               }
//
//        guard let parentKey = cachedContainerKeys[parentId] else {
//            throw PassError.unexpectedError
        ////            throw DecryptionError.parentNotDecrypted(
        ////                folderId: folderId,
        ////                parentId: parentId
        ////            )
//        }
//        parentKey = key
//        if  {
//            // Get key from storage (either from current batch or previous decryption)
//
//        } else {
//            // Root folder - use vault key
//            parentKey = try await vaultKeyProvider.getVaultKey()
//        }

        // Decrypt folder data
        return try decrypt(folder: folder, shareId: sharedId, parentKey: parentKey)
    }
}

private extension PassKeyManager {
    // TODO: generic container keys
//    func symmetricDecryptAndCache(_ encryptedShareKey: SymmetricallyEncryptedShareKey) async throws
//        -> DecryptedShareKey {
//        let shareId = encryptedShareKey.shareId
//        let keyRotation = encryptedShareKey.shareKey.keyRotation
//        let keyDescription = "share id \(shareId), keyRotation: \(keyRotation)"
//        logger.trace("Decrypting share key \(keyDescription)")
//
//        let decryptedKey = try await
//        symmetricKeyProvider.getSymmetricKey().decrypt(encryptedShareKey.encryptedKey)
//        guard let decryptedKeyData = try decryptedKey.base64Decode() else {
//            throw PassError.crypto(.failedToBase64Decode)
//        }
//        let decryptedShareKey = DecryptedShareKey(shareId: encryptedShareKey.shareId,
//                                                  keyRotation: encryptedShareKey.shareKey.keyRotation,
//                                                  keyData: decryptedKeyData)
//        decryptedShareKeys.insert(decryptedShareKey)
//            cachedContainerKeys[encryptedShareKey.shareId] = decryptedShareKey
//
//        logger.info("Decrypted & cached share key share \(keyDescription)")
//        return decryptedShareKey
//    }

    func symmetricDecryptAndCache(_ encryptedKey: SymmetricallyEncryptedKeyType) async throws
        -> any CryptographicKeyProtocol {
        let containerId = encryptedKey.id
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

//    func decryptAndCache(_ encryptedShareKey: SymmetricallyEncryptedShareKey) async throws
//        -> DecryptedShareKey {
//        let shareId = encryptedShareKey.shareId
//        let keyRotation = encryptedShareKey.shareKey.keyRotation
//        let keyDescription = "share id \(shareId), keyRotation: \(keyRotation)"
//        logger.trace("Decrypting share key \(keyDescription)")
//
//        let decryptedKey = try await
//        symmetricKeyProvider.getSymmetricKey().decrypt(encryptedShareKey.encryptedKey)
//        guard let decryptedKeyData = try decryptedKey.base64Decode() else {
//            throw PassError.crypto(.failedToBase64Decode)
//        }
//        let decryptedShareKey = DecryptedShareKey(shareId: encryptedShareKey.shareId,
//                                                  keyRotation: encryptedShareKey.shareKey.keyRotation,
//                                                  keyData: decryptedKeyData)
//        decryptedShareKeys.insert(decryptedShareKey)
//            cachedContainerKeys[encryptedShareKey.shareId] = decryptedShareKey
//
//        logger.info("Decrypted & cached share key share \(keyDescription)")
//        return decryptedShareKey
//    }

//        func decryptAndCache(_ encryptedShareKey: SymmetricallyEncryptedShareKey) async throws
//            -> DecryptedShareKey {
//            let shareId = encryptedShareKey.shareId
//            let keyRotation = encryptedShareKey.shareKey.keyRotation
//            let keyDescription = "share id \(shareId), keyRotation: \(keyRotation)"
//            logger.trace("Decrypting share key \(keyDescription)")
//
//            let decryptedKey = try await
//            symmetricKeyProvider.getSymmetricKey().decrypt(encryptedShareKey.encryptedKey)
//            guard let decryptedKeyData = try decryptedKey.base64Decode() else {
//                throw PassError.crypto(.failedToBase64Decode)
//            }
//            let decryptedShareKey = DecryptedShareKey(shareId: encryptedShareKey.shareId,
//                                                      keyRotation: encryptedShareKey.shareKey.keyRotation,
//                                                      keyData: decryptedKeyData)
//            decryptedShareKeys.insert(decryptedShareKey)
//                cachedContainerKeys[encryptedShareKey.shareId] = decryptedShareKey
//
//            logger.info("Decrypted & cached share key share \(keyDescription)")
//            return decryptedShareKey
//        }
//
//    func decryptAndCache(_ encryptedFolderKey: SymmetricallyEncryptedFolderKey) async throws
//        -> DecryptedShareKey {
//        let folderId = encryptedFolderKey.folderId
//        let keyRotation = encryptedFolderKey.keyRotation
//        let keyDescription = "Folder id \(folderId), keyRotation: \(keyRotation)"
//        logger.trace("Decrypting share key \(keyDescription)")
//
//        let decryptedKey = try await
//        symmetricKeyProvider.getSymmetricKey().decrypt(encryptedFolderKey.encryptedKey)
//        guard let decryptedKeyData = try decryptedKey.base64Decode() else {
//            throw PassError.crypto(.failedToBase64Decode)
//        }
//        let decryptedFolderKey = DecryptedFolderKey(folderId: folderId, keyRotation: keyRotation, keyData:
//        decryptedKeyData)
//
//        cachedContainerKeys[decryptedFolderKey.folderId] = decryptedFolderKey
//
//        logger.info("Decrypted & cached share key share \(keyDescription)")
//        return decryptedShareKey
//    }

//    //TODO: if first folder need to have vault key = getShareKey else need parent key m,eamiong folderkey
//    // need to loop in the calling function and order folder using parent id to have the parent key to save and
//    /access
//    func decrypt(folderKey: FolderKey,
//                 userId: String,
//                 shareId: String,
//                 folderId: String) async throws -> any DecryptionKeyProtocol {
    ////
    ////
    //////        let vaultKey = try await getShareKey(userId: userId,
    //////                                             shareId: shareId,
    //////                                             keyRotation: folderKey.keyRotation)
    ////
    ////        guard let encryptedFolderKeyData = try folderKey.folderKey.base64Decode() else {
    ////            throw PassError.crypto(.failedToBase64Decode)
    ////        }
    ////
    ////        let decryptedItemKeyData = try AES.GCM.open(encryptedItemKeyData,
    ////                                                    key: vaultKey.keyData,
    ////                                                    associatedData: .folderKey)
    ////
    ////        return DecryptedFolderKey(shareId: shareId,
    ////        folderId: <#T##String#>)
    ////            .init(shareId: shareId,
    ////                     itemId: itemId,
    ////                     keyRotation: itemKey.keyRotation,
    ////                     keyData: decryptedItemKeyData)
//    }
}
