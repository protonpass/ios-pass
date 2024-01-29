//
// IndexItemsForSpotlight.swift
// Proton Pass - Created on 29/01/2024.
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
//

import Client
import Core
import CoreSpotlight
import Entities
import Foundation

public protocol IndexItemsForSpotlightUseCase: Sendable {
    func execute(for type: SpotlightSearchableItemType) async throws
}

public extension IndexItemsForSpotlightUseCase {
    func callAsFunction(for type: SpotlightSearchableItemType) async throws {
        try await execute(for: type)
    }
}

public final class IndexItemsForSpotlight: IndexItemsForSpotlightUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let logger: Logger

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                logManager: any LogManagerProtocol) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        logger = .init(manager: logManager)
    }

    public func execute(for type: SpotlightSearchableItemType) async throws {
        logger.trace("Begin to index items for Spotlight")
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let allItems = try await itemRepository
            .getAllItems()
            .parallelMap { try $0.getItemContent(symmetricKey: symmetricKey) }

        logger.trace("Found \(allItems.count) items")

        let selectedItems = switch type {
        case .all:
            allItems
        case let .precise(type):
            allItems.filter { $0.type == type }
        }

        logger.trace("Indexing \(selectedItems.count) items for Spotlight")

        let searchableItems = try selectedItems.map { try $0.toSearchableItem() }
        try await CSSearchableIndex.default().deleteAllSearchableItems()
        try await CSSearchableIndex.default().indexSearchableItems(searchableItems)
        logger.info("Finish indexing \(selectedItems.count) items for Spotlight")
    }
}
