//
// FetchItemsForTextInsertion.swift
// Proton Pass - Created on 27/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Client
import Core
import Entities

protocol FetchItemsForTextInsertionUseCase: Sendable {
    func execute(userId: String) async throws -> ItemsForTextInsertion
}

extension FetchItemsForTextInsertionUseCase {
    func callAsFunction(userId: String) async throws -> ItemsForTextInsertion {
        try await execute(userId: userId)
    }
}

final class FetchItemsForTextInsertion: FetchItemsForTextInsertionUseCase {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let accessRepository: any AccessRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let textAutoFillDatasource: any LocalItemTextAutoFillDatasourceProtocol
    private let logger: Logger

    init(symmetricKeyProvider: any SymmetricKeyProvider,
         accessRepository: any AccessRepositoryProtocol,
         itemRepository: any ItemRepositoryProtocol,
         shareRepository: any ShareRepositoryProtocol,
         textAutoFillDatasource: any LocalItemTextAutoFillDatasourceProtocol,
         logManager: any LogManagerProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.accessRepository = accessRepository
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.textAutoFillDatasource = textAutoFillDatasource
        logger = .init(manager: logManager)
    }

    func execute(userId: String) async throws -> ItemsForTextInsertion {
        async let getSymmetricKey = symmetricKeyProvider.getSymmetricKey()
        async let getPlan = accessRepository.getPlan(userId: userId)
        async let getVaults = shareRepository.getVaults(userId: userId)
        async let getEncryptedItems = itemRepository.getItems(userId: userId, state: .active)
        async let getHistory = textAutoFillDatasource.getMostRecentItems(userId: userId,
                                                                         count: Constants.textAutoFillHistoryLimit)

        let (symmetricKey,
             plan,
             vaults,
             encryptedItems,
             history) = try await (getSymmetricKey, getPlan, getVaults, getEncryptedItems, getHistory)

        let applicableVaults = if plan.isFreeUser {
            vaults.twoOldestVaults.allVaults
        } else {
            vaults
        }

        let applicableShareIds = applicableVaults.map(\.shareId)
        let applicableEncryptedItems = encryptedItems.filter { item in
            applicableShareIds.contains(where: { $0 == item.shareId })
        }

        logger.debug("Decrypting \(applicableEncryptedItems.count) items for user \(userId)")

        let itemContents = try applicableEncryptedItems.compactMap {
            try $0.getItemContent(symmetricKey: symmetricKey)
        }

        var searchableItems = [SearchableItem]()
        var items = [ItemUiModel]()
        var historyItems = [HistoryItemUiModel]()

        for item in applicableEncryptedItems {
            let itemContent = try item.getItemContent(symmetricKey: symmetricKey)
            searchableItems.append(.init(from: itemContent, allVaults: applicableVaults))

            let uiModel = itemContent.toItemUiModel
            items.append(uiModel)
            if let historyItem = history
                .first(where: { $0.shareId == uiModel.shareId && $0.itemId == uiModel.itemId }) {
                historyItems.append(.init(time: historyItem.timestamp, value: uiModel))
            }
        }

        return .init(userId: userId,
                     vaults: applicableVaults,
                     history: historyItems,
                     searchableItems: searchableItems,
                     items: items)
    }
}
