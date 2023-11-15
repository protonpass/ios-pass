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
import Entities
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices

private let kBatchPageSize = 99

public protocol ItemRepositoryProtocol: TOTPCheckerProtocol {
    /// Get all items (both active & trashed)
    func getAllItems() async throws -> [SymmetricallyEncryptedItem]

    /// Get all local items of all shares by state
    func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get all local items of a share by state
    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get a specific Item
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem?

    /// Get alias item by alias email
    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem?

    /// Get decrypted item content
    func getItemContent(shareId: String, itemId: String) async throws -> ItemContent?

    /// Full sync for a given `shareId`
    func refreshItems(shareId: String, eventStream: VaultSyncEventStream?) async throws

    @discardableResult
    func createItem(itemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func createAlias(info: AliasCreationInfo,
                     itemContent: ProtobufableItemContentProtocol,
                     shareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func createAliasAndOtherItem(info: AliasCreationInfo,
                                 aliasItemContent: ProtobufableItemContentProtocol,
                                 otherItemContent: ProtobufableItemContentProtocol,
                                 shareId: String) async throws
        -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem)

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func deleteAlias(email: String) async throws

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func deleteItems(_ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws

    func updateItem(oldItem: ItemRevision,
                    newItemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws

    func upsertItems(_ items: [ItemRevision], shareId: String) async throws

    func update(lastUseItems: [LastUseItem], shareId: String) async throws

    func updateLastUseTime(item: ItemIdentifiable, date: Date) async throws

    @discardableResult
    func move(item: ItemIdentifiable, toShareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func move(oldEncryptedItems: [SymmetricallyEncryptedItem], toShareId: String) async throws
        -> [SymmetricallyEncryptedItem]

    @discardableResult
    func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem]

    /// Delete all local items
    func deleteAllItemsLocally() async throws

    /// Delete items locally after sync events
    func deleteAllItemsLocally(shareId: String) async throws

    /// Delete items locally after sync events
    func deleteItemsLocally(itemIds: [String], shareId: String) async throws

    // MARK: - AutoFill operations

    /// Get active log in items of all shares
    func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem]
}

public extension ItemRepositoryProtocol {
    func refreshItems(shareId: String) async throws {
        try await refreshItems(shareId: shareId, eventStream: nil)
    }
}

// swiftlint: disable discouraged_optional_self
public final class ItemRepository: ItemRepositoryProtocol {
    private let userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider
    private let localDatasource: LocalItemDatasourceProtocol
    private let remoteDatasource: RemoteItemRevisionDatasourceProtocol
    private let shareEventIDRepository: ShareEventIDRepositoryProtocol
    private let passKeyManager: PassKeyManagerProtocol
    private let logger: Logger

    public init(userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider,
                localDatasource: LocalItemDatasourceProtocol,
                remoteDatasource: RemoteItemRevisionDatasourceProtocol,
                shareEventIDRepository: ShareEventIDRepositoryProtocol,
                passKeyManager: PassKeyManagerProtocol,
                logManager: LogManagerProtocol) {
        self.userDataSymmetricKeyProvider = userDataSymmetricKeyProvider
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.shareEventIDRepository = shareEventIDRepository
        self.passKeyManager = passKeyManager
        logger = .init(manager: logManager)
    }

    public func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        logger.trace("Moving current share \(currentShareId) to share \(toShareId)")
        let oldEncryptedItems = try await getItems(shareId: currentShareId, state: .active)
        let results = try await parallelMove(oldEncryptedItems: oldEncryptedItems, to: toShareId)
        logger.trace("Moved share \(currentShareId) to share \(toShareId)")
        return results
    }
}

public extension ItemRepository {
    func getAllItems() async throws -> [SymmetricallyEncryptedItem] {
        try await localDatasource.getAllItems()
    }

    func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        try await localDatasource.getItems(state: state)
    }

    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        try await localDatasource.getItems(shareId: shareId, state: state)
    }

    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        try await localDatasource.getItem(shareId: shareId, itemId: itemId)
    }

    func getItemContent(shareId: String, itemId: String) async throws -> ItemContent? {
        let encryptedItem = try await getItem(shareId: shareId, itemId: itemId)
        return try encryptedItem?.getItemContent(symmetricKey: getSymmetricKey())
    }

    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem? {
        try await localDatasource.getAliasItem(email: email)
    }

    func refreshItems(shareId: String, eventStream: VaultSyncEventStream?) async throws {
        logger.trace("Refreshing share \(shareId)")
        let itemRevisions = try await remoteDatasource.getItemRevisions(shareId: shareId,
                                                                        eventStream: eventStream)
        logger.trace("Got \(itemRevisions.count) items from remote for share \(shareId)")

        logger.trace("Encrypting \(itemRevisions.count) remote items for share \(shareId)")
        var encryptedItems = [SymmetricallyEncryptedItem]()
        for (index, itemRevision) in itemRevisions.enumerated() {
            let encrypedItem = try await symmetricallyEncrypt(itemRevision: itemRevision, shareId: shareId)
            eventStream?.send(.decryptItems(.init(shareId: shareId,
                                                  total: itemRevisions.count,
                                                  decrypted: index + 1)))
            encryptedItems.append(encrypedItem)
        }

        logger.trace("Removing all local old items if any for share \(shareId)")
        try await localDatasource.removeAllItems(shareId: shareId)
        logger.trace("Removed all local old items for share \(shareId)")

        logger.trace("Saving \(itemRevisions.count) remote item revisions to local database")
        try await localDatasource.upsertItems(encryptedItems)
        logger.trace("Saved \(encryptedItems.count) remote item revisions to local database")

        logger.trace("Refreshing last event ID for share \(shareId)")
        let userId = try userDataSymmetricKeyProvider.getUserId()
        try await shareEventIDRepository.getLastEventId(forceRefresh: true,
                                                        userId: userId,
                                                        shareId: shareId)
        logger.trace("Refreshed last event ID for share \(shareId)")
    }

    func createItem(itemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.trace("Creating item for share \(shareId)")
        let request = try await createItemRequest(itemContent: itemContent, shareId: shareId)
        let createdItemRevision = try await remoteDatasource.createItem(shareId: shareId,
                                                                        request: request)
        logger.trace("Saving newly created item \(createdItemRevision.itemID) to local database")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: createdItemRevision, shareId: shareId)
        try await localDatasource.upsertItems([encryptedItem])
        logger.trace("Saved item \(createdItemRevision.itemID) to local database")

        return encryptedItem
    }

    func createAlias(info: AliasCreationInfo,
                     itemContent: ProtobufableItemContentProtocol,
                     shareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.trace("Creating alias item")
        let createItemRequest = try await createItemRequest(itemContent: itemContent, shareId: shareId)
        let createAliasRequest = CreateCustomAliasRequest(info: info,
                                                          item: createItemRequest)
        let createdItemRevision =
            try await remoteDatasource.createAlias(shareId: shareId,
                                                   request: createAliasRequest)
        logger.trace("Saving newly created alias \(createdItemRevision.itemID) to local database")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: createdItemRevision, shareId: shareId)
        try await localDatasource.upsertItems([encryptedItem])
        logger.trace("Saved alias \(createdItemRevision.itemID) to local database")
        return encryptedItem
    }

    func createAliasAndOtherItem(info: AliasCreationInfo,
                                 aliasItemContent: ProtobufableItemContentProtocol,
                                 otherItemContent: ProtobufableItemContentProtocol,
                                 shareId: String)
        async throws -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem) {
        logger.trace("Creating alias and another item")
        let createAliasItemRequest = try await createItemRequest(itemContent: aliasItemContent, shareId: shareId)
        let createOtherItemRequest = try await createItemRequest(itemContent: otherItemContent, shareId: shareId)
        let request = CreateAliasAndAnotherItemRequest(info: info,
                                                       aliasItem: createAliasItemRequest,
                                                       otherItem: createOtherItemRequest)
        let bundle = try await remoteDatasource.createAliasAndAnotherItem(shareId: shareId,
                                                                          request: request)
        logger.trace("Saving newly created alias & other item to local database")
        let encryptedAlias = try await symmetricallyEncrypt(itemRevision: bundle.alias, shareId: shareId)
        let encryptedOtherItem = try await symmetricallyEncrypt(itemRevision: bundle.item, shareId: shareId)
        try await localDatasource.upsertItems([encryptedAlias, encryptedOtherItem])
        logger.trace("Saved alias & other item to local database")
        return (encryptedAlias, encryptedOtherItem)
    }

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        logger.trace("Trashing \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            for batch in encryptedItems.chunked(into: kBatchPageSize) {
                logger.trace("Trashing \(batch.count) items for share \(shareId)")
                let modifiedItems =
                    try await remoteDatasource.trashItemRevisions(batch.map(\.item),
                                                                  shareId: shareId)
                try await localDatasource.upsertItems(batch,
                                                      modifiedItems: modifiedItems)
                logger.trace("Trashed \(batch.count) items for share \(shareId)")
            }
        }
    }

    func deleteAlias(email: String) async throws {
        logger.trace("Deleting alias item \(email)")
        guard let item = try await localDatasource.getAliasItem(email: email) else {
            logger.trace("Failed to delete alias item. No alias item found for \(email)")
            return
        }
        try await deleteItems([item], skipTrash: true)
    }

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        logger.trace("Untrashing \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            for batch in encryptedItems.chunked(into: kBatchPageSize) {
                logger.trace("Untrashing \(batch.count) items for share \(shareId)")
                let modifiedItems =
                    try await remoteDatasource.untrashItemRevisions(batch.map(\.item),
                                                                    shareId: shareId)
                try await localDatasource.upsertItems(batch,
                                                      modifiedItems: modifiedItems)
                logger.trace("Untrashed \(batch.count) items for share \(shareId)")
            }
        }
    }

    func deleteItems(_ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws {
        let count = items.count
        logger.trace("Deleting \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            for batch in encryptedItems.chunked(into: kBatchPageSize) {
                logger.trace("Deleting \(batch.count) items for share \(shareId)")
                try await remoteDatasource.deleteItemRevisions(batch.map(\.item),
                                                               shareId: shareId,
                                                               skipTrash: skipTrash)
                try await localDatasource.deleteItems(batch)
                logger.trace("Deleted \(batch.count) items for share \(shareId)")
            }
        }
    }

    func deleteAllItemsLocally() async throws {
        logger.trace("Deleting all items locally")
        try await localDatasource.removeAllItems()
        logger.trace("Deleted all items locally")
    }

    func deleteAllItemsLocally(shareId: String) async throws {
        logger.trace("Deleting all items locally for share \(shareId)")
        try await localDatasource.removeAllItems(shareId: shareId)
        logger.trace("Deleted all items locally for share \(shareId)")
    }

    func deleteItemsLocally(itemIds: [String], shareId: String) async throws {
        logger.trace("Deleting locally items \(itemIds) for share \(shareId)")
        try await localDatasource.deleteItems(itemIds: itemIds, shareId: shareId)
        logger.trace("Deleted locally items \(itemIds) for share \(shareId)")
    }

    func updateItem(oldItem: ItemRevision,
                    newItemContent: ProtobufableItemContentProtocol,
                    shareId: String) async throws {
        let itemId = oldItem.itemID
        logger.trace("Updating item \(itemId) for share \(shareId)")
        let latestItemKey = try await passKeyManager.getLatestItemKey(shareId: shareId,
                                                                      itemId: itemId)
        let request = try UpdateItemRequest(oldRevision: oldItem,
                                            latestItemKey: latestItemKey,
                                            itemContent: newItemContent)
        let updatedItemRevision =
            try await remoteDatasource.updateItem(shareId: shareId,
                                                  itemId: itemId,
                                                  request: request)
        logger.trace("Finished updating remotely item \(itemId) for share \(shareId)")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: updatedItemRevision, shareId: shareId)
        try await localDatasource.upsertItems([encryptedItem])
        logger.trace("Finished updating locally item \(itemId) for share \(shareId)")
    }

    func upsertItems(_ items: [ItemRevision], shareId: String) async throws {
        let encryptedItems = try await items.parallelMap { [weak self] in
            try await self?.symmetricallyEncrypt(itemRevision: $0, shareId: shareId)
        }.compactMap { $0 }
        try await localDatasource.upsertItems(encryptedItems)
    }

    func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        logger.trace("Updating \(lastUseItems.count) lastUseItem for share \(shareId)")
        try await localDatasource.update(lastUseItems: lastUseItems, shareId: shareId)
        logger.trace("Updated \(lastUseItems.count) lastUseItem for share \(shareId)")
    }

    func updateLastUseTime(item: ItemIdentifiable, date: Date) async throws {
        logger.trace("Updating last use time \(item.debugDescription)")
        let updatedItem = try await remoteDatasource.updateLastUseTime(shareId: item.shareId,
                                                                       itemId: item.itemId,
                                                                       lastUseTime: date.timeIntervalSince1970)
        try await upsertItems([updatedItem], shareId: item.shareId)
        logger.trace("Updated last use time \(item.debugDescription)")
    }

    func move(item: ItemIdentifiable, toShareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.trace("Moving \(item.debugDescription) to share \(toShareId)")
        guard let oldEncryptedItem = try await getItem(shareId: item.shareId, itemId: item.itemId) else {
            throw PassError.itemNotFound(item)
        }

        let oldItemContent = try oldEncryptedItem.getItemContent(symmetricKey: getSymmetricKey())
        let destinationShareKey = try await passKeyManager.getLatestShareKey(shareId: toShareId)
        let request = try MoveItemRequest(itemContent: oldItemContent.protobuf,
                                          destinationShareId: toShareId,
                                          destinationShareKey: destinationShareKey)
        let newItem = try await remoteDatasource.move(itemId: item.itemId,
                                                      fromShareId: item.shareId,
                                                      request: request)
        let newEncryptedItem = try await symmetricallyEncrypt(itemRevision: newItem, shareId: toShareId)
        try await localDatasource.deleteItems([oldEncryptedItem])
        try await localDatasource.upsertItems([newEncryptedItem])
        logger.info("Moved \(item.debugDescription) to share \(toShareId)")
        return newEncryptedItem
    }

    func move(oldEncryptedItems: [SymmetricallyEncryptedItem],
              toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        guard let fromSharedId = oldEncryptedItems.first?.shareId else {
            throw PassError.unexpectedError
        }

        let oldItemsContent = try oldEncryptedItems
            .map { try $0.getItemContent(symmetricKey: getSymmetricKey()) }
        let destinationShareKey = try await passKeyManager.getLatestShareKey(shareId: toShareId)

        let request = try MoveItemsRequest(itemsContent: oldItemsContent,
                                           destinationShareId: toShareId,
                                           destinationShareKey: destinationShareKey)

        let newItems = try await remoteDatasource.move(fromShareId: fromSharedId,
                                                       request: request)

        let newEncryptedItems = try await newItems
            .parallelMap { [weak self] in
                try await self?.symmetricallyEncrypt(itemRevision: $0, shareId: toShareId)
            }.compactMap { $0 }
        try await localDatasource.deleteItems(oldEncryptedItems)
        try await localDatasource.upsertItems(newEncryptedItems)

        return newEncryptedItems
    }

    func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem] {
        logger.trace("Getting local active log in items for all shares")
        let logInItems = try await localDatasource.getActiveLogInItems()
        logger.trace("Got \(logInItems.count) active log in items for all shares")
        return logInItems
    }
}

// MARK: - Private util functions

private extension ItemRepository {
    func getSymmetricKey() throws -> SymmetricKey {
        try userDataSymmetricKeyProvider.getSymmetricKey()
    }

    func symmetricallyEncrypt(itemRevision: ItemRevision,
                              shareId: String) async throws -> SymmetricallyEncryptedItem {
        let vaultKey = try await passKeyManager.getShareKey(shareId: shareId,
                                                            keyRotation: itemRevision.keyRotation)
        let contentProtobuf = try itemRevision.getContentProtobuf(vaultKey: vaultKey)
        let encryptedContent = try contentProtobuf.encrypt(symmetricKey: getSymmetricKey())

        let isLogInItem = if case .login = contentProtobuf.contentData {
            true
        } else {
            false
        }

        return .init(shareId: shareId,
                     item: itemRevision,
                     encryptedContent: encryptedContent,
                     isLogInItem: isLogInItem)
    }

    func createItemRequest(itemContent: ProtobufableItemContentProtocol,
                           shareId: String) async throws -> CreateItemRequest {
        let latestKey = try await passKeyManager.getLatestShareKey(shareId: shareId)
        return try CreateItemRequest(vaultKey: latestKey, itemContent: itemContent)
    }
}

// MARK: - TOTPCheckerProtocol

public extension ItemRepository {
    func totpCreationDateThreshold(numberOfTotp: Int) async throws -> Int64? {
        let items = try await localDatasource.getAllItems()

        let loginItemsWithTotp =
            try items
                .filter(\.isLogInItem)
                .map { try $0.getItemContent(symmetricKey: getSymmetricKey()) }
                .filter { item in
                    switch item.contentData {
                    case let .login(loginData):
                        !loginData.totpUri.isEmpty
                    default:
                        false
                    }
                }
                .sorted(by: { $0.item.createTime < $1.item.createTime })

        // Number of TOTP is not reached
        if loginItemsWithTotp.count < numberOfTotp {
            return nil
        }

        return loginItemsWithTotp.prefix(numberOfTotp).last?.item.createTime
    }
}

private extension ItemRepository {
    @discardableResult
    func parallelMove(oldEncryptedItems: [SymmetricallyEncryptedItem],
                      to toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        let splitArray = oldEncryptedItems.chunked(into: 100)
        do {
            let sortedConcurrentDatas = try await withThrowingTaskGroup(of: [SymmetricallyEncryptedItem].self,
                                                                        returning: [SymmetricallyEncryptedItem]
                                                                            .self) { [weak self] group in
                guard let self else {
                    return []
                }

                for contentToFetch in splitArray {
                    group.addTask {
                        try await self.move(oldEncryptedItems: contentToFetch,
                                            toShareId: toShareId)
                    }
                }

                let allConcurrentData = try await group
                    .reduce(into: [SymmetricallyEncryptedItem]()) { result, data in
                        result.append(contentsOf: data)
                    }
                return allConcurrentData
            }
            return sortedConcurrentDatas
        } catch {
            throw error
        }
    }
}

// swiftlint: enable discouraged_optional_self
