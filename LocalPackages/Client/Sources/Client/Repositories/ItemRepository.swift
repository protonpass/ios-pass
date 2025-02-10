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

@preconcurrency import Combine
import Core
import CoreData
@preconcurrency import CryptoKit
import Entities
import ProtonCoreLogin

// swiftlint:disable:next todo
// TODO: need to keep an eye on the evolution of Combine publisher and structured concurrency
extension CurrentValueSubject: @unchecked @retroactive Sendable {}
extension PassthroughSubject: @unchecked @retroactive Sendable {}

private let kBatchPageSize = 100

// sourcery: AutoMockable
public protocol ItemRepositoryProtocol: Sendable, TOTPCheckerProtocol {
    var currentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> { get }
    var itemsWereUpdated: CurrentValueSubject<Void, Never> { get }

    /// Get all items (both active & trashed)
    func getAllItems(userId: String) async throws -> [SymmetricallyEncryptedItem]

    /// Get all item contents
    func getAllItemContents(userId: String) async throws -> [ItemContent]

    /// Get all local items of all shares by state
    func getItems(userId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get all local items of a share by state
    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get a specific Item
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem?

    /// Get alias item by alias email
    func getAliasItem(email: String, shareId: String) async throws -> SymmetricallyEncryptedItem?

    func changeAliasStatus(userId: String, items: [any ItemIdentifiable], enabled: Bool) async throws

    /// Get decrypted item content
    func getItemContent(shareId: String, itemId: String) async throws -> ItemContent?

    func getItemRevisions(userId: String, shareId: String, itemId: String, lastToken: String?) async throws
        -> Paginated<ItemContent>

    /// Full sync for a given `shareId`
    func refreshItems(userId: String,
                      shareId: String,
                      eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws

    @discardableResult
    func createItem(userId: String,
                    itemContent: any ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func createAlias(userId: String,
                     info: AliasCreationInfo,
                     itemContent: any ProtobufableItemContentProtocol,
                     shareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func createPendingAliasesItem(userId: String,
                                  shareId: String,
                                  itemsContent: [String: any ProtobufableItemContentProtocol]) async throws
        -> [SymmetricallyEncryptedItem]

    @discardableResult
    func createAliasAndOtherItem(userId: String,
                                 info: AliasCreationInfo,
                                 aliasItemContent: any ProtobufableItemContentProtocol,
                                 otherItemContent: any ProtobufableItemContentProtocol,
                                 shareId: String) async throws
        -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem)

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func trashItems(_ items: [any ItemIdentifiable]) async throws

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func untrashItems(_ items: [any ItemIdentifiable]) async throws

    func deleteItems(userId: String, _ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws

    /// Permanently delete selected items
    func delete(userId: String, items: [any ItemIdentifiable]) async throws

    @discardableResult
    func updateItem(userId: String,
                    oldItem: Item,
                    newItemContent: any ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem

    func upsertItems(userId: String, items: [Item], shareId: String) async throws

    func update(lastUseItems: [LastUseItem], shareId: String) async throws

    func updateLastUseTime(userId: String, item: any ItemIdentifiable, date: Date) async throws

    func move(items: [any ItemIdentifiable], toShareId: String) async throws

    @discardableResult
    func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem]

    // periphery:ignore
    /// Delete all local items
    func deleteAllItemsLocally() async throws

    /// Delete all local items for current active user
    /// This should only be used for a complete nuke of local data for all users
    func deleteAllCurrentUserItemsLocally() async throws

    /// Delete items locally after sync events
    func deleteAllItemsLocally(shareId: String) async throws

    /// Delete items locally after sync events
    func deleteItemsLocally(itemIds: [String], shareId: String) async throws

    // MARK: - AutoFill operations

    /// Get active log in items of all shares
    func getActiveLogInItems(userId: String) async throws -> [SymmetricallyEncryptedItem]

    func pinItems(_ items: [any ItemIdentifiable]) async throws

    func unpinItems(_ items: [any ItemIdentifiable]) async throws

    func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem]

    func updateItemFlags(flags: [ItemFlag], shareId: String, itemId: String) async throws

    func getAllItemsContent(items: [any ItemIdentifiable]) async throws -> [ItemContent]

    func resetHistory(_ item: any ItemIdentifiable) async throws
}

public extension ItemRepositoryProtocol {
    func refreshItems(userId: String, shareId: String) async throws {
        try await refreshItems(userId: userId, shareId: shareId, eventStream: nil)
    }
}

// swiftlint: disable discouraged_optional_self file_length
public actor ItemRepository: ItemRepositoryProtocol {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let userManager: any UserManagerProtocol
    private let localDatasource: any LocalItemDatasourceProtocol
    private let remoteDatasource: any RemoteItemDatasourceProtocol
    private let shareEventIDRepository: any ShareEventIDRepositoryProtocol
    private let passKeyManager: any PassKeyManagerProtocol
    private let logger: Logger

    public nonisolated let currentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> =
        .init(nil)
    public nonisolated let itemsWereUpdated: CurrentValueSubject<Void, Never> = .init(())

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol,
                localDatasource: any LocalItemDatasourceProtocol,
                remoteDatasource: any RemoteItemDatasourceProtocol,
                shareEventIDRepository: any ShareEventIDRepositoryProtocol,
                passKeyManager: any PassKeyManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.shareEventIDRepository = shareEventIDRepository
        self.passKeyManager = passKeyManager
        self.userManager = userManager
        logger = .init(manager: logManager)
        // swiftlint:disable:next todo
        // TODO: Avoid executing unstructed task in init
        Task { [weak self] in
            guard let self else {
                return
            }
            try? await refreshPinnedItemDataStream()
        }
    }
}

public extension ItemRepository {
    func getAllItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        try await localDatasource.getAllItems(userId: userId)
    }

    func getAllItemContents(userId: String) async throws -> [ItemContent] {
        let key = try await getSymmetricKey()

        return try await getAllItems(userId: userId).parallelMap(parallelism: 50) { item in
            try item.getItemContent(symmetricKey: key)
        }
    }

    func getItems(userId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        try await localDatasource.getItems(userId: userId, state: state)
    }

    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        try await localDatasource.getItems(shareId: shareId, state: state)
    }

    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        try await localDatasource.getItem(shareId: shareId, itemId: itemId)
    }

    func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        let userId = try await userManager.getActiveUserId()
        return try await localDatasource.getAllPinnedItems(userId: userId)
    }

    func getItemContent(shareId: String, itemId: String) async throws -> ItemContent? {
        let encryptedItem = try await getItem(shareId: shareId, itemId: itemId)
        return try await encryptedItem?.getItemContent(symmetricKey: getSymmetricKey())
    }

    func getAllItemsContent(items: [any ItemIdentifiable]) async throws -> [ItemContent] {
        let items = try await localDatasource.getItems(for: items)
        let itemsContent: [ItemContent] = try await items.asyncCompactMap { [weak self] item in
            guard let self else { return nil }
            return try await item.getItemContent(symmetricKey: getSymmetricKey())
        }

        return itemsContent
    }

    func getItemRevisions(userId: String,
                          shareId: String,
                          itemId: String,
                          lastToken: String?) async throws -> Paginated<ItemContent> {
        let paginatedItems = try await remoteDatasource.getItemRevisions(userId: userId,
                                                                         shareId: shareId,
                                                                         itemId: itemId,
                                                                         lastToken: lastToken)
        let itemsContent: [ItemContent] = try await paginatedItems.data.asyncCompactMap { [weak self] item in
            guard let self else { return nil }
            return try await decrypt(userId: userId, item: item, shareId: shareId)
        }

        return Paginated(lastToken: paginatedItems.lastToken,
                         data: itemsContent,
                         total: paginatedItems.total)
    }

    func getAliasItem(email: String, shareId: String) async throws -> SymmetricallyEncryptedItem? {
        try await localDatasource.getAliasItem(email: email, shareId: shareId)
    }

    func refreshItems(userId: String,
                      shareId: String,
                      eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws {
        logger.trace("Refreshing share \(shareId)")
        let itemRevisions = try await remoteDatasource.getItems(userId: userId,
                                                                shareId: shareId,
                                                                eventStream: eventStream)
        logger.trace("Got \(itemRevisions.count) items from remote for share \(shareId)")

        logger.trace("Encrypting \(itemRevisions.count) remote items for share \(shareId)")
        var encryptedItems = [SymmetricallyEncryptedItem]()

        let symmetricKey = try await getSymmetricKey()
        for (index, itemRevision) in itemRevisions.enumerated() {
            let encryptedItem = try await symmetricallyEncrypt(itemRevision: itemRevision,
                                                               shareId: shareId,
                                                               userId: userId,
                                                               symmetricKey: symmetricKey)
            eventStream?.send(.decryptItems(.init(shareId: shareId,
                                                  total: itemRevisions.count,
                                                  decrypted: index + 1)))
            encryptedItems.append(encryptedItem)
        }

        logger.trace("Removing all local old items if any for share \(shareId)")
        try await localDatasource.removeAllItems(shareId: shareId)
        logger.trace("Removed all local old items for share \(shareId)")

        logger.trace("Saving \(itemRevisions.count) remote item revisions to local database")
        try await localDatasource.upsertItems(encryptedItems)
        logger.trace("Saved \(encryptedItems.count) remote item revisions to local database")

        logger.trace("Refreshing last event ID for share \(shareId)")
        try await shareEventIDRepository.getLastEventId(forceRefresh: true,
                                                        userId: userId,
                                                        shareId: shareId)
        try await refreshPinnedItemDataStream()
        logger.trace("Refreshed last event ID for share \(shareId)")
    }

    func createItem(userId: String,
                    itemContent: any ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.trace("Creating item for share \(shareId) and user \(userId)")
        let request = try await createItemRequest(itemContent: itemContent, userId: userId, shareId: shareId)
        let createdItemRevision = try await remoteDatasource.createItem(userId: userId,
                                                                        shareId: shareId,
                                                                        request: request)
        logger.trace("Saving newly created item \(createdItemRevision.itemID) to local database")
        let symmetricKey = try await getSymmetricKey()
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: createdItemRevision,
                                                           shareId: shareId,
                                                           userId: userId,
                                                           symmetricKey: symmetricKey)
        try await localDatasource.upsertItems([encryptedItem])
        logger.trace("Saved item \(createdItemRevision.itemID) to local database")

        return encryptedItem
    }

    func createAlias(userId: String,
                     info: AliasCreationInfo,
                     itemContent: any ProtobufableItemContentProtocol,
                     shareId: String) async throws -> SymmetricallyEncryptedItem {
        logger.trace("Creating alias item for user \(userId)")
        let createItemRequest = try await createItemRequest(itemContent: itemContent,
                                                            userId: userId,
                                                            shareId: shareId)
        let createAliasRequest = CreateCustomAliasRequest(info: info,
                                                          item: createItemRequest)
        let createdItemRevision =
            try await remoteDatasource.createAlias(userId: userId,
                                                   shareId: shareId,
                                                   request: createAliasRequest)
        logger.trace("Saving newly created alias \(createdItemRevision.itemID) to local database")
        let symmetricKey = try await getSymmetricKey()
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: createdItemRevision,
                                                           shareId: shareId,
                                                           userId: userId,
                                                           symmetricKey: symmetricKey)
        try await localDatasource.upsertItems([encryptedItem])
        logger.trace("Saved alias \(createdItemRevision.itemID) to local database")
        return encryptedItem
    }

    func createPendingAliasesItem(userId: String,
                                  shareId: String,
                                  itemsContent: [String: any ProtobufableItemContentProtocol]) async throws
        -> [SymmetricallyEncryptedItem] {
        logger.trace("Creating pending alias item for user \(userId)")

        let aliasesItemInfos = try await itemsContent.asyncCompactMap { pendingAliasId, value in
            let request = try await createItemRequest(itemContent: value,
                                                      userId: userId,
                                                      shareId: shareId)
            return AliasesItemPendingInfo(pendingAliasID: pendingAliasId, item: request)
        }

        let createPendingAliasRequest = CreateAliasesFromPendingRequest(items: aliasesItemInfos)
        let createdItemsRevision =
            try await remoteDatasource.createPendingAliasesItem(userId: userId,
                                                                shareId: shareId,
                                                                request: createPendingAliasRequest)
        logger.trace("Saving newly created aliases  to local database")
        let symmetricKey = try await getSymmetricKey()
        let encryptedItem = try await createdItemsRevision.asyncCompactMap {
            try await symmetricallyEncrypt(itemRevision: $0,
                                           shareId: shareId,
                                           userId: userId,
                                           symmetricKey: symmetricKey)
        }
        try await localDatasource.upsertItems(encryptedItem)
        logger.trace("Saved aliased to local database")
        return encryptedItem
    }

    func createAliasAndOtherItem(userId: String,
                                 info: AliasCreationInfo,
                                 aliasItemContent: any ProtobufableItemContentProtocol,
                                 otherItemContent: any ProtobufableItemContentProtocol,
                                 shareId: String)
        async throws -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem) {
        logger.trace("Creating alias and another item")
        let createAliasItemRequest = try await createItemRequest(itemContent: aliasItemContent,
                                                                 userId: userId,
                                                                 shareId: shareId)
        let createOtherItemRequest = try await createItemRequest(itemContent: otherItemContent,
                                                                 userId: userId,
                                                                 shareId: shareId)

        let request = CreateAliasAndAnotherItemRequest(info: info,
                                                       aliasItem: createAliasItemRequest,
                                                       otherItem: createOtherItemRequest)
        let bundle = try await remoteDatasource.createAliasAndAnotherItem(userId: userId,
                                                                          shareId: shareId,
                                                                          request: request)
        logger.trace("Saving newly created alias & other item to local database")
        let symmetricKey = try await getSymmetricKey()
        let encryptedAlias = try await symmetricallyEncrypt(itemRevision: bundle.alias,
                                                            shareId: shareId,
                                                            userId: userId,
                                                            symmetricKey: symmetricKey)
        let encryptedOtherItem = try await symmetricallyEncrypt(itemRevision: bundle.item,
                                                                shareId: shareId,
                                                                userId: userId,
                                                                symmetricKey: symmetricKey)
        try await localDatasource.upsertItems([encryptedAlias, encryptedOtherItem])
        logger.trace("Saved alias & other item to local database")
        return (encryptedAlias, encryptedOtherItem)
    }

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        logger.trace("Trashing \(count) items")
        let userId = try await userManager.getActiveUserId()

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            for batch in encryptedItems.chunked(into: kBatchPageSize) {
                logger.trace("Trashing \(batch.count) items for share \(shareId)")
                let modifiedItems =
                    try await remoteDatasource.trashItem(batch.map(\.item),
                                                         shareId: shareId,
                                                         userId: userId)
                try await localDatasource.upsertItems(batch,
                                                      modifiedItems: modifiedItems)
                logger.trace("Trashed \(batch.count) items for share \(shareId)")
            }
        }
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
    }

    func trashItems(_ items: [any ItemIdentifiable]) async throws {
        logger.trace("Trashing \(items.count) items")
        let userId = try await userManager.getActiveUserId()
        try await bulkAction(userId: userId, items: items) { [weak self] groupedItems, _ in
            guard let self else { return }
            try await trashItems(groupedItems)
        }
        logger.info("Trashed \(items.count) items")
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
    }

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        logger.trace("Untrashing \(count) items")
        let userId = try await userManager.getActiveUserId()

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            for batch in encryptedItems.chunked(into: kBatchPageSize) {
                logger.trace("Untrashing \(batch.count) items for share \(shareId)")
                let modifiedItems =
                    try await remoteDatasource.untrashItem(batch.map(\.item),
                                                           shareId: shareId,
                                                           userId: userId)
                try await localDatasource.upsertItems(batch,
                                                      modifiedItems: modifiedItems)
                logger.trace("Untrashed \(batch.count) items for share \(shareId)")
            }
        }
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
    }

    func untrashItems(_ items: [any ItemIdentifiable]) async throws {
        logger.trace("Bulk restoring \(items.count) items")
        let userId = try await userManager.getActiveUserId()
        try await bulkAction(userId: userId, items: items) { [weak self] groupedItems, _ in
            guard let self else { return }
            try await untrashItems(groupedItems)
        }
        logger.info("Bulk restored \(items.count) items")
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
    }

    func deleteItems(userId: String, _ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws {
        let count = items.count
        logger.trace("Deleting \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            for batch in encryptedItems.chunked(into: kBatchPageSize) {
                logger.trace("Deleting \(batch.count) items for share \(shareId)")
                try await remoteDatasource.deleteItem(batch.map(\.item),
                                                      shareId: shareId,
                                                      skipTrash: skipTrash,
                                                      userId: userId)
                try await localDatasource.deleteItems(batch)
                logger.trace("Deleted \(batch.count) items for share \(shareId)")
            }
        }
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
    }

    func delete(userId: String, items: [any ItemIdentifiable]) async throws {
        logger.trace("Bulk permanently deleting \(items.count) items")
        try await bulkAction(userId: userId, items: items) { [weak self] groupedItems, _ in
            guard let self else { return }
            try await deleteItems(userId: userId, groupedItems, skipTrash: false)
        }
        itemsWereUpdated.send()
        logger.info("Bulk permanently deleted \(items.count) items")
    }

    func deleteAllItemsLocally() async throws {
        logger.trace("Deleting all items locally")
        try await localDatasource.removeAllItems()
        try await refreshPinnedItemDataStream()
        logger.trace("Deleted all items locally")
    }

    func deleteAllCurrentUserItemsLocally() async throws {
        logger.trace("Deleting all items locally")
        let userId = try await userManager.getActiveUserId()
        try await localDatasource.removeAllItems(userId: userId)
        try await refreshPinnedItemDataStream()
        logger.trace("Deleted all items locally")
    }

    func deleteAllItemsLocally(shareId: String) async throws {
        logger.trace("Deleting all items locally for share \(shareId)")
        try await localDatasource.removeAllItems(shareId: shareId)
        try await refreshPinnedItemDataStream()
        itemsWereUpdated.send()
        logger.trace("Deleted all items locally for share \(shareId)")
    }

    func deleteItemsLocally(itemIds: [String], shareId: String) async throws {
        logger.trace("Deleting locally items \(itemIds) for share \(shareId)")
        try await localDatasource.deleteItems(itemIds: itemIds, shareId: shareId)
        try await refreshPinnedItemDataStream()
        itemsWereUpdated.send()
        logger.trace("Deleted locally items \(itemIds) for share \(shareId)")
    }

    func updateItem(userId: String,
                    oldItem: Item,
                    newItemContent: any ProtobufableItemContentProtocol,
                    shareId: String) async throws -> SymmetricallyEncryptedItem {
        let itemId = oldItem.itemID
        logger.trace("Updating item \(itemId) for share \(shareId)")

        let latestItemKey: any ShareKeyProtocol = if oldItem.isASharedWithMeItem {
            try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
        } else {
            try await passKeyManager.getLatestItemKey(userId: userId,
                                                      shareId: shareId,
                                                      itemId: itemId)
        }

        let request = try UpdateItemRequest(oldRevision: oldItem,
                                            key: latestItemKey.keyData,
                                            keyRotation: latestItemKey.keyRotation,
                                            itemContent: newItemContent)

        let updatedItemRevision =
            try await remoteDatasource.updateItem(userId: userId,
                                                  shareId: shareId,
                                                  itemId: itemId,
                                                  request: request)
        logger.trace("Finished updating remotely item \(itemId) for share \(shareId)")
        let symmetricKey = try await getSymmetricKey()
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: updatedItemRevision,
                                                           shareId: shareId,
                                                           userId: userId,
                                                           symmetricKey: symmetricKey)
        try await localDatasource.upsertItems([encryptedItem])
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
        logger.trace("Finished updating locally item \(itemId) for share \(shareId)")
        return encryptedItem
    }

    func upsertItems(userId: String, items: [Item], shareId: String) async throws {
        let symmetricKey = try await getSymmetricKey()
        let encryptedItems = try await items.parallelMap { [weak self] in
            try await self?.symmetricallyEncrypt(itemRevision: $0,
                                                 shareId: shareId,
                                                 userId: userId,
                                                 symmetricKey: symmetricKey)
        }.compactMap { $0 }

        try await localDatasource.upsertItems(encryptedItems)
        itemsWereUpdated.send()
        try await refreshPinnedItemDataStream()
    }

    func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        logger.trace("Updating \(lastUseItems.count) lastUseItem for share \(shareId)")
        try await localDatasource.update(lastUseItems: lastUseItems, shareId: shareId)
        itemsWereUpdated.send()
        logger.trace("Updated \(lastUseItems.count) lastUseItem for share \(shareId)")
    }

    func updateLastUseTime(userId: String,
                           item: any ItemIdentifiable,
                           date: Date) async throws {
        logger.trace("Updating last use time \(item.debugDescription)")

        let updatedItem = try await remoteDatasource.updateLastUseTime(userId: userId,
                                                                       shareId: item.shareId,
                                                                       itemId: item.itemId,
                                                                       lastUseTime: date.timeIntervalSince1970)
        try await upsertItems(userId: userId, items: [updatedItem], shareId: item.shareId)
        itemsWereUpdated.send()
        logger.trace("Updated last use time \(item.debugDescription)")
    }

    func move(items: [any ItemIdentifiable], toShareId: String) async throws {
        logger.trace("Bulk moving \(items.count) items to share \(toShareId)")
        let userId = try await userManager.getActiveUserId()
        try await bulkAction(userId: userId, items: items) { [weak self] groupedItems, shareId in
            guard let self else { return }
            if shareId != toShareId {
                try await parallelMove(items: groupedItems, to: toShareId)
            }
        }
        try await refreshPinnedItemDataStream()
        logger.info("Bulk moved \(items.count) items to share \(toShareId)")
    }

    func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        logger.trace("Moving current share \(currentShareId) to share \(toShareId)")
        let items = try await getItems(shareId: currentShareId, state: .active)
        let results = try await parallelMove(items: items, to: toShareId)
        itemsWereUpdated.send()
        logger.trace("Moved share \(currentShareId) to share \(toShareId)")
        return results
    }

    func getActiveLogInItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        logger.trace("Getting local active log in items for all shares")
        let logInItems = try await localDatasource.getActiveLogInItems(userId: userId)
        logger.trace("Got \(logInItems.count) active log in items for all shares")
        return logInItems
    }

    func changeAliasStatus(userId: String, items: [any ItemIdentifiable], enabled: Bool) async throws {
        let symmetricKey = try await getSymmetricKey()
        try await groupedEditItems(items) { [weak self] item in
            guard let self else { return }
            let shareId = item.shareId
            let itemId = item.itemId
            logger.trace("Update alias status item \(itemId), share \(shareId), enabled \(enabled)")
            let updatedAlias = try await remoteDatasource.toggleAliasStatus(userId: userId,
                                                                            shareId: shareId,
                                                                            itemId: itemId,
                                                                            enabled: enabled)
            logger.trace("Updating item \(updatedAlias.itemID) to local database")
            let encryptedItem = try await symmetricallyEncrypt(itemRevision: updatedAlias,
                                                               shareId: shareId,
                                                               userId: userId,
                                                               symmetricKey: symmetricKey)
            try await localDatasource.upsertItems([encryptedItem])
            logger.trace("Saved item \(updatedAlias.itemID) to local database")
        }
    }

    func resetHistory(_ item: any ItemIdentifiable) async throws {
        logger.trace("Resetting history \(item.debugDescription)")
        let userId = try await userManager.getActiveUserId()
        let updatedItem = try await remoteDatasource.resetHistory(userId: userId,
                                                                  shareId: item.shareId,
                                                                  itemId: item.itemId)
        try await upsertItems(userId: userId, items: [updatedItem], shareId: item.shareId)
        logger.trace("Finish resetting history \(item.debugDescription)")
    }
}

// MARK: - item Pinning functionalities

public extension ItemRepository {
    func pinItems(_ items: [any ItemIdentifiable]) async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Pinning \(items.count) items for user \(userId)")
        let symmetricKey = try await getSymmetricKey()
        try await groupedEditItems(items) { [weak self] item in
            guard let self else { return }
            let pinnedItem = try await remoteDatasource.pin(userId: userId, item: item)
            let encryptedItem = try await symmetricallyEncrypt(itemRevision: pinnedItem,
                                                               shareId: item.shareId,
                                                               userId: userId,
                                                               symmetricKey: symmetricKey)
            try await localDatasource.upsertItems([encryptedItem])
        }
        logger.info("Finish pinning \(items.count) items for user \(userId)")
        try await refreshPinnedItemDataStream()
    }

    func unpinItems(_ items: [any ItemIdentifiable]) async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Unpinning \(items.count) items for user \(userId)")
        let symmetricKey = try await getSymmetricKey()
        try await groupedEditItems(items) { [weak self] item in
            guard let self else { return }
            let pinnedItem = try await remoteDatasource.unpin(userId: userId, item: item)
            let encryptedItem = try await symmetricallyEncrypt(itemRevision: pinnedItem,
                                                               shareId: item.shareId,
                                                               userId: userId,
                                                               symmetricKey: symmetricKey)
            try await localDatasource.upsertItems([encryptedItem])
        }
        logger.info("Finish unpinning \(items.count) items for user \(userId)")
        try await refreshPinnedItemDataStream()
    }
}

// MARK: - Item flags

public extension ItemRepository {
    func updateItemFlags(flags: [ItemFlag],
                         shareId: String,
                         itemId: String) async throws {
        logger.trace("Update flags for item \(itemId) of share \(shareId)")
        let request = UpdateItemFlagsRequest(flags: flags)
        let userId = try await userManager.getActiveUserId()
        let symmetricKey = try await getSymmetricKey()
        let itemWithUpdatedFlags = try await remoteDatasource.updateItemFlags(userId: userId,
                                                                              itemId: itemId,
                                                                              shareId: shareId,
                                                                              request: request)
        logger.trace("Updating item \(itemWithUpdatedFlags.itemID) to local database")
        let encryptedItem = try await symmetricallyEncrypt(itemRevision: itemWithUpdatedFlags,
                                                           shareId: shareId,
                                                           userId: userId,
                                                           symmetricKey: symmetricKey)
        try await localDatasource.upsertItems([encryptedItem])
        logger.trace("Saved item \(itemWithUpdatedFlags.itemID) to local database")
        itemsWereUpdated.send()
    }
}

// MARK: - Refresh Data

private extension ItemRepository {
    func refreshPinnedItemDataStream() async throws {
        let userId = try await userManager.getActiveUserId()
        let pinnedItems = try await localDatasource.getAllPinnedItems(userId: userId)
        currentlyPinnedItems.send(pinnedItems)
    }
}

// MARK: - Private util functions

private extension ItemRepository {
    func getSymmetricKey() async throws -> SymmetricKey {
        try await symmetricKeyProvider.getSymmetricKey()
    }

    func symmetricallyEncrypt(itemRevision: Item,
                              shareId: String,
                              userId: String,
                              symmetricKey: SymmetricKey) async throws -> SymmetricallyEncryptedItem {
        let shareKey = try await passKeyManager.getShareKey(userId: userId,
                                                            shareId: shareId,
                                                            keyRotation: itemRevision.keyRotation)

        let contentProtobuf = try itemRevision.getContentProtobuf(shareKey: shareKey)

        let encryptedContent = try contentProtobuf.encrypt(symmetricKey: symmetricKey)

        let isLogInItem = if case .login = contentProtobuf.contentData {
            true
        } else {
            false
        }

        return .init(shareId: shareId,
                     userId: userId,
                     item: itemRevision,
                     encryptedContent: encryptedContent,
                     isLogInItem: isLogInItem)
    }

    func createItemRequest(itemContent: any ProtobufableItemContentProtocol,
                           userId: String,
                           shareId: String) async throws -> CreateItemRequest {
        let latestKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
        return try CreateItemRequest(vaultKey: latestKey, itemContent: itemContent)
    }
}

// MARK: - TOTPCheckerProtocol

public extension ItemRepository {
    func totpCreationDateThreshold(numberOfTotp: Int) async throws -> Int64? {
        let userId = try await userManager.getActiveUserId()

        let items = try await localDatasource.getAllItems(userId: userId)
        let symmetricKey = try await getSymmetricKey()

        let loginItemsWithTotp =
            try items
                .filter(\.isLogInItem)
                .map { try $0.getItemContent(symmetricKey: symmetricKey) }
                .compactMap { itemContent -> Item? in
                    guard case let .login(loginData) = itemContent.contentData,
                          !loginData.totpUri.isEmpty
                    else {
                        return nil
                    }
                    return itemContent.item
                }
                .sorted(by: { $0.createTime < $1.createTime })

        // Number of TOTP is not reached
        if loginItemsWithTotp.count < numberOfTotp {
            return nil
        }

        return loginItemsWithTotp.prefix(numberOfTotp).last?.createTime
    }
}

private extension ItemRepository {
    @discardableResult
    func parallelMove(items: [any ItemIdentifiable],
                      to toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        let splitArray = items.chunked(into: 10)
        do {
            let sortedConcurrentDatas = try await withThrowingTaskGroup(of: [SymmetricallyEncryptedItem].self,
                                                                        returning: [SymmetricallyEncryptedItem]
                                                                            .self) { [weak self] group in
                guard let self else {
                    return []
                }

                for contentToFetch in splitArray {
                    group.addTask {
                        try await self.doMove(items: contentToFetch,
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

    @discardableResult
    func doMove(items: [any ItemIdentifiable],
                toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        guard let fromSharedId = items.first?.shareId else {
            throw PassError.unexpectedError
        }
        let userId = try await userManager.getActiveUserId()
        let symmetricKey = try await getSymmetricKey()

        let destinationShareKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: toShareId)

        var itemsToBeMoved = [ItemToBeMoved]()
        for item in items {
            // Get all decrypted item keys
            let decryptedItemKeys = try await passKeyManager.getItemKeys(userId: userId,
                                                                         shareId: item.shareId,
                                                                         itemId: item.itemId)
            // Re-encrypt all those item keys with the destination vault key
            var encryptedItemKeys = [ItemKey]()
            for itemKey in decryptedItemKeys {
                let encryptedItemKey = try AES.GCM.seal(itemKey.keyData,
                                                        key: destinationShareKey.keyData,
                                                        associatedData: .itemKey)
                encryptedItemKeys.append(.init(key: encryptedItemKey.base64EncodedString(),
                                               keyRotation: itemKey.keyRotation))
            }
            itemsToBeMoved.append(.init(itemId: item.itemId,
                                        itemKeys: encryptedItemKeys))
        }

        let request = MoveItemsRequest(shareId: toShareId, items: itemsToBeMoved)
        let newItems = try await remoteDatasource.move(userId: userId,
                                                       fromShareId: fromSharedId,
                                                       request: request)

        let newEncryptedItems = try await newItems
            .parallelMap { [weak self] in
                try await self?.symmetricallyEncrypt(itemRevision: $0,
                                                     shareId: toShareId,
                                                     userId: userId,
                                                     symmetricKey: symmetricKey)
            }.compactMap { $0 }
        try await localDatasource.deleteItems(itemIds: items.map(\.itemId),
                                              shareId: fromSharedId)
        try await localDatasource.upsertItems(newEncryptedItems)
        return newEncryptedItems
    }

    /// Group items by share and bulk actionning on those grouped items
    func bulkAction(userId: String,
                    items: [any ItemIdentifiable],
                    action: @Sendable ([SymmetricallyEncryptedItem], ShareID) async throws -> Void) async throws {
        let shouldInclude: @Sendable (SymmetricallyEncryptedItem) -> Bool = { item in
            items.contains(where: { $0.isEqual(with: item) })
        }
        let allItems = try await getAllItems(userId: userId)
        try await allItems.groupAndBulkAction(by: \.shareId,
                                              shouldInclude: shouldInclude,
                                              action: action)
    }

    func groupedEditItems(_ items: [any ItemIdentifiable],
                          action: @escaping @Sendable (any ItemIdentifiable) async throws -> Void) async throws {
        if items.count == 1, let firstItem = items.first {
            /// Avoid `TaskGroup` overhead when there's only 1 item
            try await action(firstItem)
        } else {
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for item in items {
                    taskGroup.addTask {
                        try await action(item)
                    }
                }
            }
        }
    }
}

private extension ItemRepository {
    func decrypt(userId: String, item: Item, shareId: String) async throws -> ItemContent {
        let shareKey = try await passKeyManager.getShareKey(userId: userId,
                                                            shareId: shareId,
                                                            keyRotation: item.keyRotation)
        let contentProtobuf = try item.getContentProtobuf(shareKey: shareKey)
        return ItemContent(userId: userId, shareId: shareId, item: item, contentProtobuf: contentProtobuf)
    }
}

// swiftlint: enable discouraged_optional_self file_length
