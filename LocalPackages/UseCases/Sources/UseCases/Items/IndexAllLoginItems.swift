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
import Entities
import Foundation

/// Empty credential database and index all existing login items
/// We only index if user enabled "QuickType bar" option but in case when
/// user is enabling but not yet enabled "QuickType bar" option we need to bypass
/// by ignoring what is currently set in preferences.
public protocol IndexAllLoginItemsUseCase: Sendable {
    func execute(ignorePreferences: Bool) async throws
}

public extension IndexAllLoginItemsUseCase {
    func callAsFunction(ignorePreferences: Bool) async throws {
        try await execute(ignorePreferences: ignorePreferences)
    }
}

public final class IndexAllLoginItems: @unchecked Sendable, IndexAllLoginItemsUseCase {
    private let itemRepository: ItemRepositoryProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let accessRepository: AccessRepositoryProtocol
    private let credentialManager: CredentialManagerProtocol
    private let preferences: PreferencesProtocol
    private let mapLoginItem: MapLoginItemUseCase
    private let logger: Logger

    public init(itemRepository: ItemRepositoryProtocol,
                shareRepository: ShareRepositoryProtocol,
                accessRepository: AccessRepositoryProtocol,
                credentialManager: CredentialManagerProtocol,
                preferences: PreferencesProtocol,
                mapLoginItem: MapLoginItemUseCase,
                logManager: LogManagerProtocol) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.accessRepository = accessRepository
        self.preferences = preferences
        self.credentialManager = credentialManager
        self.mapLoginItem = mapLoginItem
        logger = .init(manager: logManager)
    }

    public func execute(ignorePreferences: Bool) async throws {
        let start = Date()
        logger.trace("Indexing all login items")

        guard preferences.quickTypeBar || ignorePreferences else {
            logger.trace("Skipped indexing all login items. QuickType bar not enabled")
            return
        }

        guard await credentialManager.isAutoFillEnabled else {
            logger.trace("Skipped indexing all login items. AutoFill not enabled")
            return
        }

        try await credentialManager.removeAllCredentials()
        let items = try await filterItems()

        let credentials = try items.flatMap(mapLoginItem.execute)
        try await credentialManager.insert(credentials: credentials)

        let time = Date().timeIntervalSince1970 - start.timeIntervalSince1970
        let priority = Task.currentPriority.debugDescription
        logger.info("Indexed \(items.count) login items in \(time) seconds with priority \(priority)")
    }
}

private extension IndexAllLoginItems {
    func filterItems() async throws -> [SymmetricallyEncryptedItem] {
        let plan = try await accessRepository.getPlan()
        let items = try await itemRepository.getActiveLogInItems()
        logger.trace("Found \(items.count) active login items")
        if !plan.isFreeUser {
            return items
        }
        let vaults = try await shareRepository.getVaults()
        let oldestVaults = vaults.twoOldestVaults
        return items.filter { oldestVaults.isOneOf(shareId: $0.shareId) }
    }
}
