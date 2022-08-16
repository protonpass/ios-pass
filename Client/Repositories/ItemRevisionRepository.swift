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

public protocol ItemRevisionRepositoryProtocol {
    var userId: String { get }
    var shareId: String { get }
    var localItemRevisionDatasoure: LocalItemRevisionDatasourceProtocol { get }
    var remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol { get }

    func getItemRevisions(forceRefresh: Bool,
                          page: Int,
                          pageSize: Int) async throws -> ItemRevisionList
    @discardableResult
    func createItem(request: CreateItemRequest) async throws -> ItemRevision
}

public extension ItemRevisionRepositoryProtocol {
    func getItemRevisions(forceRefresh: Bool,
                          page: Int,
                          pageSize: Int) async throws -> ItemRevisionList {
        PPLogger.shared?.log("Getting item revisions (page =\(page), pageSize = \(pageSize))")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh item revisions (page =\(page), pageSize = \(pageSize))")
            return try await getItemRevisionsFromRemoteAndSaveToLocal(page: page,
                                                                      pageSize: pageSize)
        }

        let localItemRevisionList =
        try await localItemRevisionDatasoure.getItemRevisions(shareId: shareId,
                                                              page: page,
                                                              pageSize: pageSize)

        if localItemRevisionList.revisionsData.isEmpty {
            PPLogger.shared?.log("""
No item revisions in local => Fetching from remote... (page =\(page), pageSize = \(pageSize))
""")
            return try await getItemRevisionsFromRemoteAndSaveToLocal(page: page,
                                                                      pageSize: pageSize)
        }

        PPLogger.shared?.log("""
Found \(localItemRevisionList.revisionsData.count) item revision in local (page =\(page), pageSize = \(pageSize))
""")
        return localItemRevisionList
    }

    private func getItemRevisionsFromRemoteAndSaveToLocal(
        page: Int,
        pageSize: Int
    ) async throws -> ItemRevisionList {
        PPLogger.shared?.log("Getting item revisions from remote (page =\(page), pageSize = \(pageSize))")
        let itemRevisionList =
        try await remoteItemRevisionDatasource.getItemRevisions(shareId: shareId,
                                                                page: page,
                                                                pageSize: pageSize)
        PPLogger.shared?.log("Saving remote item revisions to local (page =\(page), pageSize = \(pageSize))")
        let itemRevisions = itemRevisionList.revisionsData
        try await localItemRevisionDatasoure.upsertItemRevisions(itemRevisions,
                                                                 shareId: shareId)
        return itemRevisionList
    }

    func createItem(request: CreateItemRequest) async throws -> ItemRevision {
        PPLogger.shared?.log("Creating item revisions")
        let createdItemRevision =
        try await remoteItemRevisionDatasource.createItem(shareId: shareId,
                                                          request: request)
        PPLogger.shared?.log("Saving newly create item revision to local")
        try await localItemRevisionDatasoure.upsertItemRevisions([createdItemRevision],
                                                                 shareId: shareId)
        PPLogger.shared?.log("Item revision creation finished with success")
        return createdItemRevision
    }
}

public struct ItemRevisionRepository: ItemRevisionRepositoryProtocol {
    public let userId: String
    public let shareId: String
    public let localItemRevisionDatasoure: LocalItemRevisionDatasourceProtocol
    public let remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol

    public init(userId: String,
                shareId: String,
                localItemRevisionDatasoure: LocalItemRevisionDatasourceProtocol,
                remoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol) {
        self.userId = userId
        self.shareId = shareId
        self.localItemRevisionDatasoure = localItemRevisionDatasoure
        self.remoteItemRevisionDatasource = remoteItemRevisionDatasource
    }
}
