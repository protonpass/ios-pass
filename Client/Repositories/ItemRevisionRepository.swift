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

    func getItemRevisions(forceRefresh: Bool, shareId: String) async throws -> [ItemRevision]
    @discardableResult
    func createItem(request: CreateItemRequest, shareId: String) async throws -> ItemRevision
}

public extension ItemRevisionRepositoryProtocol {
    func getItemRevision(shareId: String, itemId: String) async throws -> ItemRevision? {
        try await localItemRevisionDatasoure.getItemRevision(shareId: shareId, itemId: itemId)
    }

    func getItemRevisions(forceRefresh: Bool, shareId: String) async throws -> [ItemRevision] {
        PPLogger.shared?.log("Getting item revisions")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh item revisions")
            return try await refreshItemRevisions(shareId: shareId)
        }

        let localItemRevisions = try await localItemRevisionDatasoure.getItemRevisions(shareId: shareId)

        if localItemRevisions.isEmpty {
            PPLogger.shared?.log("No item revisions in local databse => Fetch from remote")
            return try await refreshItemRevisions(shareId: shareId)
        }

        PPLogger.shared?.log("Found \(localItemRevisions.count) item revision in local database")
        return localItemRevisions
    }

    private func refreshItemRevisions(shareId: String) async throws -> [ItemRevision] {
        PPLogger.shared?.log("Getting item revisions from remote")
        let itemRevisions = try await remoteItemRevisionDatasource.getItemRevisions(shareId: shareId)
        PPLogger.shared?.log("Saving \(itemRevisions.count) remote item revisions to local database")
        try await localItemRevisionDatasoure.upsertItemRevisions(itemRevisions, shareId: shareId)
        return itemRevisions
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
