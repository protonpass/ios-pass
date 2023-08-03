//
// IndexAllLoginItems.swift
// Proton Pass - Created on 03/08/2023.
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

import Client
import Core

/// Empty credential database and reindex all existing login items
protocol IndexAllLoginItemsUseCase: Sendable {
    func execute() async throws
}

extension IndexAllLoginItemsUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

final class IndexAllLoginItems: @unchecked Sendable, IndexAllLoginItemsUseCase {
    private let itemRepository: ItemRepositoryProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let passPlanRepository: PassPlanRepositoryProtocol
    private let credentialManager: CredentialManagerProtocol
    private let mapLoginItem: MapLoginItemUseCase
    private let logger: Logger

    init(itemRepository: ItemRepositoryProtocol,
         shareRepository: ShareRepositoryProtocol,
         passPlanRepository: PassPlanRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         mapLoginItem: MapLoginItemUseCase,
         logManager: LogManagerProtocol) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.passPlanRepository = passPlanRepository
        self.credentialManager = credentialManager
        self.mapLoginItem = mapLoginItem
        logger = .init(manager: logManager)
    }

    func execute() async throws {
        logger.trace("Indexing all login items")
        guard await credentialManager.isAutoFillEnabled() else {
            logger.trace("AutoFill not enabled, skipped indexing all login items")
            return
        }

        try await credentialManager.removeAllCredentials()

        var items = try await itemRepository.getActiveLogInItems()
        logger.trace("Found \(items.count) active login items")

        let plan = try await passPlanRepository.getPlan()
        if plan.isFreeUser {
            // Only index items in primary vault for free users
            let vaults = try await shareRepository.getVaults()
            let primaryVault = vaults.first { $0.isPrimary }
            items = items.filter { $0.shareId == primaryVault?.shareId }
            logger.trace("Filtered \(items.count) active login items")
        }

        let credentials = try items.flatMap(mapLoginItem.execute)
        try await credentialManager.insert(credentials: credentials)
        logger.info("Indexed \(items.count) login items")
    }
}
