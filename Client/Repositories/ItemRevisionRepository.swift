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

    func getItemRevisions(forceRefresh: Bool,
                          shareId: String,
                          state: ItemRevisionState) async throws -> [ItemRevision]

    @discardableResult
    func createItem(request: CreateItemRequest, shareId: String) async throws -> ItemRevision

    @discardableResult
    func trashItem(request: TrashItemsRequest, shareId: String) async throws -> [ItemToBeTrashed]
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

    func createItem(request: CreateItemRequest,
                    shareId: String) async throws -> ItemRevision {
        PPLogger.shared?.log("Creating item revisions")
        let createdItemRevision =
        try await remoteItemRevisionDatasource.createItem(shareId: shareId,
                                                          request: request)
        PPLogger.shared?.log("Saving newly create item revision to local database")
        try await localItemRevisionDatasoure.upsertItemRevisions([createdItemRevision],
                                                                 shareId: shareId)
        PPLogger.shared?.log("Item revision creation finished with success")
        return createdItemRevision
    }

    func trashItem(request: TrashItemsRequest, shareId: String) async throws -> [ItemToBeTrashed] {
        PPLogger.shared?.log("Trashing items for share \(shareId)")
        let itemsToBeTrashed = try await remoteItemRevisionDatasource.trashItem(shareId: shareId, request: request)
        PPLogger.shared?.log("Finished trashing remotely \(itemsToBeTrashed.count) items for share \(shareId)")
        try await localItemRevisionDatasoure.trashItem(shareId: shareId, itemsToBeTrashed: itemsToBeTrashed)
        PPLogger.shared?.log("Finished trashing locallly \(itemsToBeTrashed.count) items for share \(shareId)")
        return itemsToBeTrashed
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
