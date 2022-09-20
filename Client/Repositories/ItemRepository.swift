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

public protocol ItemRepositoryProtocol {
    var userData: UserData { get }
    var symmetricKey: SymmetricKey { get }
    var localItemDatasoure: LocalItemDatasourceProtocol { get }
    var remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol { get }
    var publicKeyRepository: PublicKeyRepositoryProtocol { get }
    var shareRepository: ShareRepositoryProtocol { get }
    var shareKeysRepository: ShareKeysRepositoryProtocol { get }

    /// Get a specific Item
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem?

    /// Get item of a share by state
    func getItems(forceRefresh: Bool,
                  shareId: String,
                  state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    @discardableResult
    func createItem(request: CreateItemRequest, shareId: String) async throws -> SymmetricallyEncryptedItem

    @discardableResult
    func createAlias(request: CreateCustomAliasRequest,
                     shareId: String) async throws -> SymmetricallyEncryptedItem

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws

    func deleteItems(_ items: [SymmetricallyEncryptedItem], shareId: String) async throws

    func updateItem(request: UpdateItemRequest, shareId: String, itemId: String) async throws
}

public extension ItemRepositoryProtocol {
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        try await localItemDatasoure.getItem(shareId: shareId, itemId: itemId)
    }

    func getItems(forceRefresh: Bool,
                  shareId: String,
                  state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        let stateDescription: String
        switch state {
        case .active: stateDescription = "active"
        case .trashed: stateDescription = "trashed"
        }

        PPLogger.shared?.log("Getting \(stateDescription) item revisions")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh item revisions")
            try await refreshItems(shareId: shareId)
        }

        let localItemCount = try await localItemDatasoure.getItemCount(shareId: shareId)

        if localItemCount == 0 {
            PPLogger.shared?.log("No item in local database => Fetch from remote")
            try await refreshItems(shareId: shareId)
        }

        let localItems = try await localItemDatasoure.getItems(shareId: shareId, state: state)

        let count = localItems.count
        PPLogger.shared?.log("Found \(count) \(stateDescription) items in local database")
        return localItems
    }

    func createItem(request: CreateItemRequest,
                    shareId: String) async throws -> SymmetricallyEncryptedItem {
        PPLogger.shared?.log("Creating item for share \(shareId)")
        let createdItemRevision = try await remoteItemRevisionDatasource.createItem(shareId: shareId,
                                                                                    request: request)
        PPLogger.shared?.log("Saving newly created item \(createdItemRevision.itemID) to local database")
        let encryptedItem = try await map(itemRevision: createdItemRevision, shareId: shareId)
        try await localItemDatasoure.upsertItems([encryptedItem])
        PPLogger.shared?.log("Saved item \(createdItemRevision.itemID) to local database")
        return encryptedItem
    }

    func createAlias(request: CreateCustomAliasRequest,
                     shareId: String) async throws -> SymmetricallyEncryptedItem {
        PPLogger.shared?.log("Creating alias item")
        let createdItemRevision = try await remoteItemRevisionDatasource.createAlias(shareId: shareId,
                                                                                     request: request)
        PPLogger.shared?.log("Saving newly created alias \(createdItemRevision.itemID) to local database")
        let encryptedItem = try await map(itemRevision: createdItemRevision, shareId: shareId)
        try await localItemDatasoure.upsertItems([encryptedItem])
        PPLogger.shared?.log("Saved alias \(createdItemRevision.itemID) to local database")
        return encryptedItem
    }

    func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        PPLogger.shared?.log("Trashing \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            let items = encryptedItems.map { $0.item }
            let modifiedItems =
            try await remoteItemRevisionDatasource.trashItemRevisions(items,
                                                                      shareId: shareId)
            PPLogger.shared?.log("Finished trashing remotely \(items.count) items for share \(shareId)")
            try await localItemDatasoure.upsertItems(encryptedItems,
                                                     modifiedItems: modifiedItems)
            PPLogger.shared?.log("Finished trashing locallly \(items.count) items for share \(shareId)")
        }
    }

    func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let count = items.count
        PPLogger.shared?.log("Untrashing \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            let items = encryptedItems.map { $0.item }
            let modifiedItems =
            try await remoteItemRevisionDatasource.untrashItemRevisions(items,
                                                                        shareId: shareId)
            PPLogger.shared?.log("Finished untrashing remotely \(items.count) items for share \(shareId)")
            try await localItemDatasoure.upsertItems(encryptedItems,
                                                     modifiedItems: modifiedItems)
            PPLogger.shared?.log("Finished untrashing locallly \(items.count) items for share \(shareId)")
        }
    }

    func deleteItems(_ items: [SymmetricallyEncryptedItem], shareId: String) async throws {
        let count = items.count
        PPLogger.shared?.log("Deleting \(count) items")

        let itemsByShareId = Dictionary(grouping: items, by: { $0.shareId })
        for shareId in itemsByShareId.keys {
            guard let encryptedItems = itemsByShareId[shareId] else { continue }
            let items = encryptedItems.map { $0.item }
            try await remoteItemRevisionDatasource.deleteItemRevisions(items, shareId: shareId)
            PPLogger.shared?.log("Finished deleting remotely \(items.count) items for share \(shareId)")
            try await localItemDatasoure.deleteItems(encryptedItems)
            PPLogger.shared?.log("Finished deleting locallly \(items.count) items for share \(shareId)")
        }
    }

    func updateItem(request: UpdateItemRequest, shareId: String, itemId: String) async throws {
        PPLogger.shared?.log("Updating item \(itemId) for share \(shareId)")
        let updatedItemRevision = try await remoteItemRevisionDatasource.updateItem(shareId: shareId,
                                                                                    itemId: itemId,
                                                                                    request: request)
        PPLogger.shared?.log("Finished updating remotely item \(itemId) for share \(shareId)")
        let encryptedItem = try await map(itemRevision: updatedItemRevision, shareId: shareId)
        try await localItemDatasoure.upsertItems([encryptedItem])
        PPLogger.shared?.log("Finished updating locally item \(itemId) for share \(shareId)")
    }
}

private extension ItemRepositoryProtocol {
    func refreshItems(shareId: String) async throws {
        PPLogger.shared?.log("Getting items from remote")
        let itemRevisions = try await remoteItemRevisionDatasource.getItemRevisions(shareId: shareId)
        PPLogger.shared?.log("Get \(itemRevisions.count) items from remote")

        PPLogger.shared?.log("Saving \(itemRevisions.count) remote item revisions to local database")
        var encryptedItems = [SymmetricallyEncryptedItem]()
        for itemRevision in itemRevisions {
            let encrypedItem = try await map(itemRevision: itemRevision, shareId: shareId)
            encryptedItems.append(encrypedItem)
        }
        try await localItemDatasoure.upsertItems(encryptedItems)
        PPLogger.shared?.log("Saved \(encryptedItems.count) remote item revisions to local database")
    }

    func getShareAndKeys(shareId: String) async throws -> (Share, ShareKeys) {
        let share = try await shareRepository.getShare(shareId: shareId)
        let shareKeys = try await shareKeysRepository.getShareKeys(shareId: shareId,
                                                                   page: 0,
                                                                   pageSize: kDefaultPageSize,
                                                                   forceRefresh: true)
        return (share, shareKeys)
    }

    func map(itemRevision: ItemRevision, shareId: String) async throws -> SymmetricallyEncryptedItem {
        let (share, shareKeys) = try await getShareAndKeys(shareId: shareId)
        let publicKeys =
        try await publicKeyRepository.getPublicKeys(email: itemRevision.signatureEmail)
        let verifyKeys = publicKeys.map { $0.value }
        let contentProtobuf = try itemRevision.getContentProtobuf(userData: userData,
                                                                  share: share,
                                                                  vaultKeys: shareKeys.vaultKeys,
                                                                  itemKeys: shareKeys.itemKeys,
                                                                  verifyKeys: verifyKeys)
        let encryptedContentProtobuf = try contentProtobuf.symmetricallyEncrypted(symmetricKey)
        let encryptedContent = try encryptedContentProtobuf.serializedData().base64EncodedString()
        return .init(shareId: shareId, item: itemRevision, encryptedContent: encryptedContent)
    }
}

public struct ItemRepository: ItemRepositoryProtocol {
    public let userData: UserData
    public let symmetricKey: SymmetricKey
    public let localItemDatasoure: LocalItemDatasourceProtocol
    public let remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol
    public let publicKeyRepository: PublicKeyRepositoryProtocol
    public let shareRepository: ShareRepositoryProtocol
    public let shareKeysRepository: ShareKeysRepositoryProtocol

    public init(userData: UserData,
                symmetricKey: SymmetricKey,
                localItemDatasoure: LocalItemDatasourceProtocol,
                remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol,
                publicKeyRepository: PublicKeyRepositoryProtocol,
                shareRepository: ShareRepositoryProtocol,
                shareKeysRepository: ShareKeysRepositoryProtocol) {
        self.userData = userData
        self.symmetricKey = symmetricKey
        self.localItemDatasoure = localItemDatasoure
        self.remoteItemRevisionDatasource = remoteItemRevisionDatasource
        self.publicKeyRepository = publicKeyRepository
        self.shareRepository = shareRepository
        self.shareKeysRepository = shareKeysRepository
    }
}
