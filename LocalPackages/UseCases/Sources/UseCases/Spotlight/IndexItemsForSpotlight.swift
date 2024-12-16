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
    func execute(_ settings: any SpotlightSettingsProvider) async throws
}

public extension IndexItemsForSpotlightUseCase {
    func callAsFunction(_ settings: any SpotlightSettingsProvider) async throws {
        try await execute(settings)
    }
}

public final class IndexItemsForSpotlight: IndexItemsForSpotlightUseCase {
    private let userManager: any UserManagerProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let datasource: any LocalSpotlightVaultDatasourceProtocol
    private let logger: Logger

    public init(userManager: any UserManagerProtocol,
                itemRepository: any ItemRepositoryProtocol,
                datasource: any LocalSpotlightVaultDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.userManager = userManager
        self.itemRepository = itemRepository
        self.datasource = datasource
        logger = .init(manager: logManager)
    }

    public func execute(_ settings: any SpotlightSettingsProvider) async throws {
        guard settings.spotlightEnabled else {
            logger.trace("Spotlight is disabled, removing all indexed items")
            try await CSSearchableIndex.default().deleteAllSearchableItems()
            logger.trace("Removed all spotlight indexed items")
            return
        }
        let userId = try await userManager.getActiveUserId()

        logger.trace("Begin to index items for Spotlight")
        let allItems = try await itemRepository.getAllItemContents(userId: userId)

        logger.trace("Found \(allItems.count) items")

        let selectedItems: [ItemContent]
        switch settings.spotlightSearchableVaults {
        case .all:
            selectedItems = allItems
            logger.trace("Indexing \(selectedItems.count) items in all vaults for Spotlight")
        case .selected:
            let ids = try await datasource.getIds(for: userId)
            selectedItems = allItems.filter { ids.contains($0.shareId) }
            logger.trace("Indexing \(selectedItems.count) items in \(ids.count) vaults for Spotlight")
        }

        let content = settings.spotlightSearchableContent
        let searchableItems = try selectedItems.map { try $0.toSearchableItem(content: content) }
        // Optionally delete all indexed items because sometimes errors may arise
        // we don't want to stop the indexation process
        try? await CSSearchableIndex.default().deleteAllSearchableItems()
        try await CSSearchableIndex.default().indexSearchableItems(searchableItems)
        logger.info("Finish indexing \(selectedItems.count) items for Spotlight")
    }
}
