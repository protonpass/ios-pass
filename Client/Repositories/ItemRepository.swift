//
// ItemRepository.swift
// Proton Pass - Created on 20/09/2022.
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

import Core
import CoreData
import CryptoKit
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services

public protocol ItemRepositoryDelegate: AnyObject {
    func itemRepositoryHasNewCredentials(_ credentials: [AutoFillCredential])
    func itemRepositoryDeletedCredentials(_ credentials: [AutoFillCredential])
}

public protocol ItemRepositoryProtocol {
    var userData: UserData { get }
    var symmetricKey: SymmetricKey { get }
    var localItemDatasoure: LocalItemDatasourceProtocol { get }
    var remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol { get }
    var publicKeyRepository: PublicKeyRepositoryProtocol { get }
    var shareRepository: ShareRepositoryProtocol { get }
    var shareEventIDRepository: ShareEventIDRepositoryProtocol { get }
    var vaultItemKeysRepository: VaultItemKeysRepositoryProtocol { get }
    var logger: LoggerV2 { get }
    var delegate: ItemRepositoryDelegate? { get }

    /// Get a specific Item
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem?

    /// Get alias item by alias email
    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem?

    func getDecryptedItemContent(shareId: String, itemId: String) async throws -> ItemContent?

    /// Get items of all shares by state
    func getItems(forceRefresh: Bool, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get item of a share by state
    func getItems(forceRefresh: Bool,
                  shareId: String,
                  state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    @discardableResult
    func createItem(itemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func createAlias(info: AliasCreationInfo,
                     itemContent: ProtobufableItemContentProtocol,
                     shareId: String) async throws -> SymmetricallyEncryptedItem

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func deleteAlias(email: String) async throws

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func deleteItems(_ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws

    func updateItem(oldItem: ItemRevision,
                    newItemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws

    func upsertItems(_ items: [ItemRevision], shareId: String) async throws

    /// Delete items locally after sync events
    func deleteItemsLocally(itemIds: [String], shareId: String) async throws

    // MARK: - AutoFill operations
    /// Get active log in items of all shares
    func getActiveLogInItems(forceRefresh: Bool) async throws -> [SymmetricallyEncryptedItem]

    /// Update the last use time of an item. Only log in items are concerned.
    func update(item: SymmetricallyEncryptedItem, lastUseTime: TimeInterval) async throws
}

public extension ItemRepositoryProtocol {
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        try await localItemDatasoure.getItem(shareId: shareId, itemId: itemId)
    }

    func getDecryptedItemContent(shareId: String, itemId: String) async throws -> ItemContent? {
        let encryptedItem = try await getItem(shareId: shareId, itemId: itemId)
        return try encryptedItem?.getDecryptedItemContent(symmetricKey: symmetricKey)
    }

    func getItems(forceRefresh: Bool,
                  shareId: String,
                  state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        let stateDescription: String
        switch state {
        case .active: stateDescription = "active"
        case .trashed: stateDescription = "trashed"
        }

        logger.info("Getting \(stateDescription) item revisions")
        if forceRefresh {
            logger.info("Force refresh item revisions")
            try await refreshItems(shareId: shareId)
        }

        let localItemCount = try await localItemDatasoure.getItemCount(shareId: shareId)

        if localItemCount == 0 {
            logger.info("No item in local database => Fetch from remote")
            try await refreshItems(shareId: shareId)
        }

        let localItems = try await localItemDatasoure.getItems(shareId: shareId, state: state)

        let count = localItems.count
        logger.info("Found \(count) \(stateDescription) items in local database")
        return localItems
    }

    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem? {
        try await localItemDatasoure.getAliasItem(email: email)
    }

    func getItems(forceRefresh: Bool, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        let shares = try await shareRepository.getShares(forceRefresh: forceRefresh)
        var allItems = [SymmetricallyEncryptedItem]()
        for share in shares {
            let items = try await getItems(forceRefresh: forceRefresh,
                                           shareId: share.shareID,
                                           state: state)
            allItems.append(contentsOf: items)
        }
        return allItems
    }

    func createItem(itemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.info("Creating item for share \(shareId)")
        let request = try await createItemRequest(itemContent: itemContent, shareId: shareId)
        let createdItemRevision = try await remoteItemRevisionDatasource.createItem(shareId: shareId,
                                                                                    request: request)
        logger.info("Saving newly created item \(createdItemRevision.itemID) to local database")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: createdItemRevision, shareId: shareId)
        try await localItemDatasoure.upsertItems([encryptedItem])
        logger.info("Saved item \(createdItemRevision.itemID) to local database")

        let newCredentials = try getCredentials(from: [encryptedItem], state: .active)
        delegate?.itemRepositoryHasNewCredentials(newCredentials)
        logger.info("Delegated \(newCredentials.count) new credentials")

        return encryptedItem
    }

    func createAlias(info: AliasCreationInfo,
                     itemContent: ProtobufableItemContentProtocol,
                     shareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.info("Creating alias item")
        let createItemRequest = try await createItemRequest(itemContent: itemContent, shareId: shareId)
        let createAliasRequest = CreateCustomAliasRequest(info: info,
                                                          item: createItemRequest)
        let createdItemRevision =
        try await remoteItemRevisionDatasource.createAlias(shareId: shareId,
                                                           request: createAliasRequest)
        logger.info("Saving newly created alias \(createdItemRevision.itemID) to local database")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: createdItemRevision, shareId: shareId)
        try await localItemDatasoure.upsertItems([encryptedItem])
        logger.info("Saved alias \(createdItemRevision.itemID) to local database")
        return encryptedItem
    }

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        logger.info("Trashing \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            let items = encryptedItems.map { $0.item }
            let modifiedItems =
            try await remoteItemRevisionDatasource.trashItemRevisions(items,
                                                                      shareId: shareId)
            logger.info("Finished trashing remotely \(items.count) items for share \(shareId)")
            try await localItemDatasoure.upsertItems(encryptedItems,
                                                     modifiedItems: modifiedItems)
            logger.info("Finished trashing locallly \(items.count) items for share \(shareId)")
        }

        logger.info("Extracting deleted credentials from \(items.count) deleted items")
        let deletedCredentials = try getCredentials(from: items, state: .active)
        delegate?.itemRepositoryDeletedCredentials(deletedCredentials)
        logger.info("Delegated \(deletedCredentials.count) deleted credentials")
    }

    func deleteAlias(email: String) async throws {
        logger.info("Deleting alias item \(email)")
        guard let item = try await localItemDatasoure.getAliasItem(email: email) else {
            logger.info("Failed to delete alias item. No alias item found for \(email)")
            return
        }
        try await deleteItems([item], skipTrash: true)
    }

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        logger.info("Untrashing \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            let items = encryptedItems.map { $0.item }
            let modifiedItems =
            try await remoteItemRevisionDatasource.untrashItemRevisions(items,
                                                                        shareId: shareId)
            logger.info("Finished untrashing remotely \(items.count) items for share \(shareId)")
            try await localItemDatasoure.upsertItems(encryptedItems,
                                                     modifiedItems: modifiedItems)
            logger.info("Finished untrashing locallly \(items.count) items for share \(shareId)")
        }

        logger.info("Extracting new credentials from \(items.count) untrashed items")
        let newCredentials = try getCredentials(from: items, state: .trashed)
        delegate?.itemRepositoryHasNewCredentials(newCredentials)
        logger.info("Delegated \(newCredentials.count) new credentials")
    }

    func deleteItems(_ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws {
        let count = items.count
        logger.info("Deleting \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            let items = encryptedItems.map { $0.item }
            try await remoteItemRevisionDatasource.deleteItemRevisions(items,
                                                                       shareId: shareId,
                                                                       skipTrash: skipTrash)
            logger.info("Finished deleting remotely \(items.count) items for share \(shareId)")
            try await localItemDatasoure.deleteItems(encryptedItems)
            logger.info("Finished deleting locallly \(items.count) items for share \(shareId)")
        }
    }

    func deleteItemsLocally(itemIds: [String], shareId: String) async throws {
        try await localItemDatasoure.deleteItems(itemIds: itemIds, shareId: shareId)
    }

    func updateItem(oldItem: ItemRevision,
                    newItemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws {
        let itemId = oldItem.itemID
        logger.info("Updating item \(itemId) for share \(shareId)")
        let encryptedOldItemContentData = try await localItemDatasoure.getItem(shareId: shareId, itemId: itemId)
        let decryptedOldItemContentData =
        try encryptedOldItemContentData?.getDecryptedItemContent(symmetricKey: symmetricKey)
        let keysAndPassphrases = try await getKeysAndPassphrases(shareId: shareId)
        let request = try UpdateItemRequest(oldRevision: oldItem,
                                            vaultKey: keysAndPassphrases.vaultKey,
                                            vaultKeyPassphrase: keysAndPassphrases.vaultKeyPassphrase,
                                            itemKey: keysAndPassphrases.itemKey,
                                            itemKeyPassphrase: keysAndPassphrases.itemKeyPassphrase,
                                            addressKey: userData.getAddressKey(),
                                            itemContent: newItemContent)
        let updatedItemRevision =
        try await remoteItemRevisionDatasource.updateItem(shareId: shareId,
                                                          itemId: itemId,
                                                          request: request)
        logger.info("Finished updating remotely item \(itemId) for share \(shareId)")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: updatedItemRevision, shareId: shareId)
        try await localItemDatasoure.upsertItems([encryptedItem])
        logger.info("Finished updating locally item \(itemId) for share \(shareId)")

        if case let .login(oldUsername, _, oldUrls) = decryptedOldItemContentData?.contentData,
           case let .login(newUsername, _, newUrls) = newItemContent.contentData {
            let ids = AutoFillCredential.IDs(shareId: shareId, itemId: itemId)
            let deletedCredentials = oldUrls.map { oldUrl in
                AutoFillCredential(ids: ids,
                                   username: oldUsername,
                                   url: oldUrl,
                                   lastUseTime: encryptedItem.item.lastUseTime)
            }
            let newCredentials = newUrls.map { newUrl in
                AutoFillCredential(ids: ids,
                                   username: newUsername,
                                   url: newUrl,
                                   lastUseTime: encryptedItem.item.lastUseTime)
            }
            delegate?.itemRepositoryDeletedCredentials(deletedCredentials)
            delegate?.itemRepositoryHasNewCredentials(newCredentials)
            logger.info("Delegated updated credential")
        }
    }

    func upsertItems(_ items: [ItemRevision], shareId: String) async throws {
        let encryptedItems = try await items.parallelMap {
            try await symmetricallyEncrypt(itemRevision: $0, shareId: shareId)
        }
        try await localItemDatasoure.upsertItems(encryptedItems)
    }

    func getActiveLogInItems(forceRefresh: Bool) async throws -> [SymmetricallyEncryptedItem] {
        logger.info("Getting active log in items for all shares")
        let shares = try await shareRepository.getShares(forceRefresh: forceRefresh)
        var allLogInItems = [SymmetricallyEncryptedItem]()
        for share in shares {
            if forceRefresh {
                logger.info("Forcing refresh items for share \(share.shareID)")
                _ = try await remoteItemRevisionDatasource.getItemRevisions(shareId: share.shareID)
            }
            logger.info("Getting active log in items for share \(share.shareID)")
            let logInItems = try await localItemDatasoure.getActiveLogInItems(shareId: share.shareID)
            logger.info("Found \(logInItems.count) active log in items for share \(share.shareID)")
            allLogInItems.append(contentsOf: logInItems)
        }
        logger.info("Found \(allLogInItems.count) active log in items for all shares")
        return allLogInItems
    }

    func update(item: SymmetricallyEncryptedItem, lastUseTime: TimeInterval) async throws {
        logger.info("Updating item's (\(item.item.itemID) lastUsedTime \(lastUseTime)")
        let updatedItem =
        try await remoteItemRevisionDatasource.updateLastUseTime(shareId: item.shareId,
                                                                 itemId: item.itemId,
                                                                 lastUseTime: lastUseTime)
        let encryptedUpdatedItem = try await symmetricallyEncrypt(itemRevision: updatedItem,
                                                                  shareId: item.shareId)
        try await localItemDatasoure.upsertItems([encryptedUpdatedItem])
        logger.info("Updated item's (\(item.item.itemID) lastUsedTime \(lastUseTime)")
    }
}

// MARK: - Private util functions
private extension ItemRepositoryProtocol {
    func refreshItems(shareId: String) async throws {
        logger.info("Getting items from remote")
        let itemRevisions = try await remoteItemRevisionDatasource.getItemRevisions(shareId: shareId)
        logger.info("Get \(itemRevisions.count) items from remote")

        logger.info("Saving \(itemRevisions.count) remote item revisions to local database")
        var encryptedItems = [SymmetricallyEncryptedItem]()
        for itemRevision in itemRevisions {
            let encrypedItem = try await symmetricallyEncrypt(itemRevision: itemRevision, shareId: shareId)
            encryptedItems.append(encrypedItem)
        }
        try await localItemDatasoure.upsertItems(encryptedItems)
        logger.info("Saved \(encryptedItems.count) remote item revisions to local database")

        logger.info("Refreshing last event ID for share \(shareId)")
        try await shareEventIDRepository.getLastEventId(forceRefresh: true,
                                                        userId: userData.user.ID,
                                                        shareId: shareId)
        logger.info("Refreshed last event ID for share \(shareId)")

        logger.info("Extracting new credentials from \(encryptedItems.count) remote items")
        let newCredentials = try getCredentials(from: encryptedItems, state: .active)
        delegate?.itemRepositoryHasNewCredentials(newCredentials)
        logger.info("Delegated \(newCredentials.count) new credentials")
    }

    func symmetricallyEncrypt(itemRevision: ItemRevision,
                              shareId: String) async throws -> SymmetricallyEncryptedItem {
        let share = try await shareRepository.getShare(shareId: shareId)
        let vaultKeys = try await vaultItemKeysRepository.getVaultKeys(shareId: shareId, forceRefresh: false)
        let itemKeys = try await vaultItemKeysRepository.getItemKeys(shareId: shareId, forceRefresh: false)
        let publicKeys = try await publicKeyRepository.getPublicKeys(email: itemRevision.signatureEmail)
        let verifyKeys = publicKeys.map { $0.value }
        let contentProtobuf = try itemRevision.getContentProtobuf(userData: userData,
                                                                  share: share,
                                                                  vaultKeys: vaultKeys,
                                                                  itemKeys: itemKeys,
                                                                  verifyKeys: verifyKeys)
        let encryptedContentProtobuf = try contentProtobuf.symmetricallyEncrypted(symmetricKey)
        let encryptedContent = try encryptedContentProtobuf.serializedData().base64EncodedString()

        let isLogInItem: Bool
        if case .login = contentProtobuf.contentData {
            isLogInItem = true
        } else {
            isLogInItem = false
        }

        return .init(shareId: shareId,
                     item: itemRevision,
                     encryptedContent: encryptedContent,
                     isLogInItem: isLogInItem)
    }

    func getCredentials(from encryptedItems: [SymmetricallyEncryptedItem],
                        state: ItemState) throws -> [AutoFillCredential] {
        let encryptedLogInItems = encryptedItems.filter { $0.item.itemState == state }
        var credentials = [AutoFillCredential]()
        for encryptedLogInItem in encryptedLogInItems {
            let decryptedLogInItem = try encryptedLogInItem.getDecryptedItemContent(symmetricKey: symmetricKey)
            if case let .login(username, _, urls) = decryptedLogInItem.contentData {
                for url in urls {
                    credentials.append(.init(ids: .init(shareId: decryptedLogInItem.shareId,
                                                        itemId: decryptedLogInItem.item.itemID),
                                             username: username,
                                             url: url,
                                             lastUseTime: encryptedLogInItem.item.lastUseTime))
                }
            }
        }
        return credentials
    }

    func createItemRequest(itemContent: ProtobufableItemContentProtocol,
                           shareId: String) async throws -> CreateItemRequest {
        let keysAndPassphrases = try await getKeysAndPassphrases(shareId: shareId)
        return try CreateItemRequest(vaultKey: keysAndPassphrases.vaultKey,
                                     vaultKeyPassphrase: keysAndPassphrases.vaultKeyPassphrase,
                                     itemKey: keysAndPassphrases.itemKey,
                                     itemKeyPassphrase: keysAndPassphrases.itemKeyPassphrase,
                                     addressKey: keysAndPassphrases.addressKey,
                                     itemContent: itemContent)
    }

    func getKeysAndPassphrases(shareId: String) async throws -> KeysAndPassphrases {
        let latestVaultItemKeys = try await vaultItemKeysRepository.getLatestVaultItemKeys(shareId: shareId,
                                                                                           forceRefresh: false)
        let latestVaultKey = latestVaultItemKeys.vaultKey
        let latestItemKey = latestVaultItemKeys.itemKey
        let share = try await shareRepository.getShare(shareId: shareId)
        let vaultKeyPassphrase = try PassKeyUtils.getVaultKeyPassphrase(userData: userData,
                                                                        share: share,
                                                                        vaultKey: latestVaultKey)
        guard let itemKeyPassphrase =
                try PassKeyUtils.getItemKeyPassphrase(vaultKey: latestVaultKey,
                                                      vaultKeyPassphrase: vaultKeyPassphrase,
                                                      itemKey: latestItemKey) else {
            fatalError("Post MVP")
        }
        return .init(vaultKey: latestVaultKey,
                     vaultKeyPassphrase: vaultKeyPassphrase,
                     itemKey: latestItemKey,
                     itemKeyPassphrase: itemKeyPassphrase,
                     addressKey: try userData.getAddressKey())
    }
}

// MARK: - Public supporting tasks
public extension ItemRepositoryProtocol {
    func getItemTask(shareId: String, itemId: String) async throws
    -> Task<SymmetricallyEncryptedItem?, Error> {
        Task.detached(priority: .userInitiated) {
            try await getItem(shareId: shareId, itemId: itemId)
        }
    }
}

public final class ItemRepository: ItemRepositoryProtocol {
    public let userData: UserData
    public let symmetricKey: SymmetricKey
    public let localItemDatasoure: LocalItemDatasourceProtocol
    public let remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol
    public let publicKeyRepository: PublicKeyRepositoryProtocol
    public let shareRepository: ShareRepositoryProtocol
    public let shareEventIDRepository: ShareEventIDRepositoryProtocol
    public let vaultItemKeysRepository: VaultItemKeysRepositoryProtocol
    public let logger: LoggerV2
    public weak var delegate: ItemRepositoryDelegate?

    public init(userData: UserData,
                symmetricKey: SymmetricKey,
                localItemDatasoure: LocalItemDatasourceProtocol,
                remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol,
                publicKeyRepository: PublicKeyRepositoryProtocol,
                shareRepository: ShareRepositoryProtocol,
                shareEventIDRepository: ShareEventIDRepositoryProtocol,
                vaultItemKeysRepository: VaultItemKeysRepositoryProtocol,
                logManager: LogManager) {
        self.userData = userData
        self.symmetricKey = symmetricKey
        self.localItemDatasoure = localItemDatasoure
        self.remoteItemRevisionDatasource = remoteItemRevisionDatasource
        self.publicKeyRepository = publicKeyRepository
        self.shareRepository = shareRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.vaultItemKeysRepository = vaultItemKeysRepository
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    public init(userData: UserData,
                symmetricKey: SymmetricKey,
                container: NSPersistentContainer,
                apiService: APIService,
                logManager: LogManager) {
        self.userData = userData
        self.symmetricKey = symmetricKey
        let authCredential = userData.credential
        self.localItemDatasoure = LocalItemDatasource(container: container)
        self.remoteItemRevisionDatasource = RemoteItemRevisionDatasource(authCredential: authCredential,
                                                                         apiService: apiService)
        self.publicKeyRepository = PublicKeyRepository(container: container,
                                                       apiService: apiService,
                                                       logManager: logManager)
        self.shareRepository = ShareRepository(userData: userData,
                                               container: container,
                                               authCredential: authCredential,
                                               apiService: apiService)
        self.shareEventIDRepository = ShareEventIDRepository(container: container,
                                                             authCredential: authCredential,
                                                             apiService: apiService)
        self.vaultItemKeysRepository = VaultItemKeysRepository(container: container,
                                                               authCredential: authCredential,
                                                               apiService: apiService)
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }
}

private struct KeysAndPassphrases {
    let vaultKey: VaultKey
    let vaultKeyPassphrase: String
    let itemKey: ItemKey
    let itemKeyPassphrase: String
    let addressKey: AddressKey
}
