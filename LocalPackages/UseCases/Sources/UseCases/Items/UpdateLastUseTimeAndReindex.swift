//
// UpdateLastUseTimeAndReindex.swift
// Proton Pass - Created on 14/11/2023.
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
//

import AuthenticationServices
import Client
import Entities
import Foundation

public protocol UpdateLastUseTimeAndReindexUseCase: Sendable {
    func execute(item: ItemContent,
                 date: Date,
                 identifiers: [ASCredentialServiceIdentifier]) async throws
}

public extension UpdateLastUseTimeAndReindexUseCase {
    func callAsFunction(item: ItemContent,
                        date: Date,
                        identifiers: [ASCredentialServiceIdentifier]) async throws {
        try await execute(item: item, date: date, identifiers: identifiers)
    }
}

public final class UpdateLastUseTimeAndReindex: UpdateLastUseTimeAndReindexUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let localItemDatasource: any LocalItemDatasourceProtocol
    private let localShareDatasource: any LocalShareDatasourceProtocol
    private let reindexLoginItem: any ReindexLoginItemUseCase

    public init(itemRepository: any ItemRepositoryProtocol,
                localItemDatasource: any LocalItemDatasourceProtocol,
                localShareDatasource: any LocalShareDatasourceProtocol,
                reindexLoginItem: any ReindexLoginItemUseCase) {
        self.itemRepository = itemRepository
        self.localItemDatasource = localItemDatasource
        self.localShareDatasource = localShareDatasource
        self.reindexLoginItem = reindexLoginItem
    }

    /// Last use time is bound to users so even if ones don't have write access,
    /// they can still update the last use of an item
    ///
    /// So we check for all the related items of a given item
    /// (same item living in different vaults of different users because of sharing)
    ///
    /// Those items share the same `ItemID` but different `ShareID`
    /// however those `ShareID` share the same `VaultID`
    public func execute(item: ItemContent,
                        date: Date,
                        identifiers: [ASCredentialServiceIdentifier]) async throws {
        /// We get the `Share` of the item in order to know its `VaultID`
        guard let share = try await localShareDatasource.getShare(userId: item.userId,
                                                                  shareId: item.shareId) else {
            throw PassError.shareNotFoundInLocalDB(shareID: item.shareId)
        }

        /// From the `VaultID`, we get all the related `ShareID`
        let shares = try await localShareDatasource.getAllShares(vaultId: share.share.vaultID)
        let shareIds = shares.map(\.share.shareID)

        for shareId in shareIds {
            /// We loop through all these related `ShareID` and update the last use time of the corresponding items
            if let itemContent = try await itemRepository.getItemContent(shareId: shareId,
                                                                         itemId: item.itemId) {
                try await itemRepository.updateLastUseTime(userId: itemContent.userId,
                                                           item: itemContent,
                                                           date: date)
            }
        }
        try await reindexLoginItem(item: item,
                                   identifiers: identifiers,
                                   lastUseTime: date)
    }
}
