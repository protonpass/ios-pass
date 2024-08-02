//
//
// GetSearchableItems.swift
// Proton Pass - Created on 30/11/2023.
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

import Client
import Entities
import Foundation

public protocol GetSearchableItemsUseCase: Sendable {
    func execute(userId: String, for searchMode: SearchMode) async throws -> [SearchableItem]
}

public extension GetSearchableItemsUseCase {
    func callAsFunction(userId: String, for searchMode: SearchMode) async throws -> [SearchableItem] {
        try await execute(userId: userId, for: searchMode)
    }
}

public final class GetSearchableItems: GetSearchableItemsUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let getAllPinnedItems: any GetAllPinnedItemsUseCase
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                getAllPinnedItems: any GetAllPinnedItemsUseCase,
                symmetricKeyProvider: any SymmetricKeyProvider) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.getAllPinnedItems = getAllPinnedItems
        self.symmetricKeyProvider = symmetricKeyProvider
    }

    public func execute(userId: String, for searchMode: SearchMode) async throws -> [SearchableItem] {
        async let getVaults = shareRepository.getVaults(userId: userId)
        async let getItems = getEncryptedItems(userId: userId, searchMode: searchMode)
        async let getSymmetricKey = symmetricKeyProvider.getSymmetricKey()
        let (vaults, items, symmetricKey) = try await (getVaults, getItems, getSymmetricKey)
        return try items.map { try SearchableItem(from: $0,
                                                  symmetricKey: symmetricKey,
                                                  allVaults: vaults) }
    }
}

private extension GetSearchableItems {
    func getEncryptedItems(userId: String, searchMode: SearchMode) async throws -> [SymmetricallyEncryptedItem] {
        switch searchMode {
        case .pinned:
            try await getAllPinnedItems()
        case let .all(vaultSelection):
            switch vaultSelection {
            case .all:
                try await itemRepository.getItems(userId: userId, state: .active)
            case let .precise(vault):
                try await itemRepository.getItems(shareId: vault.shareId, state: .active)
            case .trash:
                try await itemRepository.getItems(userId: userId, state: .trashed)
            }
        }
    }
}
