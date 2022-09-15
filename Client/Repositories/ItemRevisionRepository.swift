//
// ItemRevisionRepository.swift
// Proton Pass - Created on 16/08/2022.
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
import ProtonCore_Networking
import ProtonCore_Services

public protocol ItemRevisionRepositoryProtocol {
    var localItemRevisionDatasoure: LocalItemRevisionDatasourceProtocol { get }
    var remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol { get }

    /// Get a specific ItemRevision (only from local datasource)
    func getItemRevision(shareId: String, itemId: String) async throws -> ItemRevision?

    /// Get item revisions of a share by state
    func getItemRevisions(forceRefresh: Bool,
                          shareId: String,
                          state: ItemRevisionState) async throws -> [ItemRevision]

    @discardableResult
    func createItem(request: CreateItemRequest, shareId: String) async throws -> ItemRevision

    @discardableResult
    func createAlias(request: CreateCustomAliasRequest, shareId: String) async throws -> ItemRevision

    func trashItemRevisions(_ items: [ItemRevision], shareId: String) async throws

    func untrashItemRevisions(_ items: [ItemRevision], shareId: String) async throws

    func deleteItemRevisions(_ items: [ItemRevision], shareId: String) async throws

    func updateItem(request: UpdateItemRequest, shareId: String, itemId: String) async throws
}

public extension ItemRevisionRepositoryProtocol {
    func getItemRevision(shareId: String, itemId: String) async throws -> ItemRevision? {
        try await localItemRevisionDatasoure.getItemRevision(shareId: shareId, itemId: itemId)
    }

    func getItemRevisions(forceRefresh: Bool,
                          shareId: String,
                          state: ItemRevisionState) async throws -> [ItemRevision] {
        let stateDescription: String
        switch state {
        case .active: stateDescription = "active"
        case .trashed: stateDescription = "trashed"
        }

        PPLogger.shared?.log("Getting \(stateDescription) item revisions")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh item revisions")
            try await refreshItemRevisions(shareId: shareId)
        }

        let localItemRevisionCount =
        try await localItemRevisionDatasoure.getItemRevisionCount(shareId: shareId)

        if localItemRevisionCount == 0 {
            PPLogger.shared?.log("No item revisions in local database => Fetch from remote")
            try await refreshItemRevisions(shareId: shareId)
        }

        let localItemRevisions =
        try await localItemRevisionDatasoure.getItemRevisions(shareId: shareId, state: state)

        let count = localItemRevisions.count
        PPLogger.shared?.log("Found \(count) \(stateDescription) item revisions in local database")
        return localItemRevisions
    }

    private func refreshItemRevisions(shareId: String) async throws {
        PPLogger.shared?.log("Getting item revisions from remote")
        let itemRevisions = try await remoteItemRevisionDatasource.getItemRevisions(shareId: shareId)
        PPLogger.shared?.log("Saving \(itemRevisions.count) remote item revisions to local database")
        try await localItemRevisionDatasoure.upsertItemRevisions(itemRevisions, shareId: shareId)
    }

    func createItem(request: CreateItemRequest, shareId: String) async throws -> ItemRevision {
        PPLogger.shared?.log("Creating item revisions")
        let createdItemRevision = try await remoteItemRevisionDatasource.createItem(shareId: shareId,
                                                                                    request: request)
        PPLogger.shared?.log("Saving newly create item revision to local database")
        try await localItemRevisionDatasoure.upsertItemRevisions([createdItemRevision], shareId: shareId)
        PPLogger.shared?.log("Item revision creation finished with success")
        return createdItemRevision
    }

    func createAlias(request: CreateCustomAliasRequest, shareId: String) async throws -> ItemRevision {
        PPLogger.shared?.log("Creating alias item")
        let createdItemRevision = try await remoteItemRevisionDatasource.createAlias(shareId: shareId,
                                                                                     request: request)
        PPLogger.shared?.log("Saving newly create alias item to local database")
        try await localItemRevisionDatasoure.upsertItemRevisions([createdItemRevision], shareId: shareId)
        PPLogger.shared?.log("Alias item creation finished with success")
        return createdItemRevision
    }

    func trashItemRevisions(_ items: [ItemRevision], shareId: String) async throws {
        let count = items.count
        PPLogger.shared?.log("Trashing \(count) items for share \(shareId)")
        let modifiedItems = try await remoteItemRevisionDatasource.trashItemRevisions(items, shareId: shareId)
        PPLogger.shared?.log("Finished trashing remotely \(count) items for share \(shareId)")
        try await localItemRevisionDatasoure.upsertItemRevisions(items,
                                                                 modifiedItems: modifiedItems,
                                                                 shareId: shareId)
        PPLogger.shared?.log("Finished trashing locallly \(count) items for share \(shareId)")
    }

    func untrashItemRevisions(_ items: [ItemRevision], shareId: String) async throws {
        let count = items.count
        PPLogger.shared?.log("Untrashing \(count) items for share \(shareId)")
        let modifiedItems = try await remoteItemRevisionDatasource.untrashItemRevisions(items,
                                                                                        shareId: shareId)
        PPLogger.shared?.log("Finished untrashing remotely \(count) items for share \(shareId)")
        try await localItemRevisionDatasoure.upsertItemRevisions(items,
                                                                 modifiedItems: modifiedItems,
                                                                 shareId: shareId)
        PPLogger.shared?.log("Finished untrashing locallly \(count) items for share \(shareId)")
    }

    func deleteItemRevisions(_ items: [ItemRevision], shareId: String) async throws {
        let count = items.count
        PPLogger.shared?.log("Deleting \(count) items for share \(shareId)")
        try await remoteItemRevisionDatasource.deleteItemRevisions(items, shareId: shareId)
        PPLogger.shared?.log("Finished deleting remotely \(count) items for share \(shareId)")
        try await localItemRevisionDatasoure.deleteItemRevisions(items, shareId: shareId)
        PPLogger.shared?.log("Finished deleting locallly \(count) items for share \(shareId)")
    }

    func updateItem(request: UpdateItemRequest, shareId: String, itemId: String) async throws {
        PPLogger.shared?.log("Updating item \(itemId) for share \(shareId)")
        let updatedItemRevision = try await remoteItemRevisionDatasource.updateItem(shareId: shareId,
                                                                                    itemId: itemId,
                                                                                    request: request)
        PPLogger.shared?.log("Finished updating remotely item \(itemId) for share \(shareId)")
        try await localItemRevisionDatasoure.upsertItemRevisions([updatedItemRevision], shareId: shareId)
        PPLogger.shared?.log("Finished updating locally item \(itemId) for share \(shareId)")
    }
}

public struct ItemRevisionRepository: ItemRevisionRepositoryProtocol {
    public let localItemRevisionDatasoure: LocalItemRevisionDatasourceProtocol
    public let remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol

    public init(localItemRevisionDatasoure: LocalItemRevisionDatasourceProtocol,
                remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol) {
        self.localItemRevisionDatasoure = localItemRevisionDatasoure
        self.remoteItemRevisionDatasource = remoteItemRevisionDatasource
    }

    public init(container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService) {
        self.localItemRevisionDatasoure = LocalItemRevisionDatasource(container: container)
        self.remoteItemRevisionDatasource = RemoteItemRevisionDatasource(authCredential: authCredential,
                                                                         apiService: apiService)
    }
}
