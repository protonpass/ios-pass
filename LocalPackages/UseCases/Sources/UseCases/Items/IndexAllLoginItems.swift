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
public protocol IndexAllLoginItemsUseCase: Sendable {
    func execute() async throws
}

public extension IndexAllLoginItemsUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class IndexAllLoginItems: @unchecked Sendable, IndexAllLoginItemsUseCase {
    private let userManager: any UserManagerProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let localAccessDatasource: any LocalAccessDatasourceProtocol
    private let credentialManager: any CredentialManagerProtocol
    private let mapLoginItem: any MapLoginItemUseCase
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let logger: Logger

    public init(userManager: any UserManagerProtocol,
                itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                localAccessDatasource: any LocalAccessDatasourceProtocol,
                credentialManager: any CredentialManagerProtocol,
                mapLoginItem: any MapLoginItemUseCase,
                symmetricKeyProvider: any SymmetricKeyProvider,
                logManager: any LogManagerProtocol) {
        self.userManager = userManager
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.localAccessDatasource = localAccessDatasource
        self.credentialManager = credentialManager
        self.mapLoginItem = mapLoginItem
        self.symmetricKeyProvider = symmetricKeyProvider
        logger = .init(manager: logManager)
    }

    public func execute() async throws {
        let start = Date()
        logger.trace("Indexing all login items")

        guard await credentialManager.isAutoFillEnabled else {
            logger.trace("Skipped indexing all login items. AutoFill not enabled")
            return
        }

        try await credentialManager.removeAllCredentials()
        let userIds = userManager.allUserAccounts.value.map(\.user.ID)

        // Step 1: get all the vaults from all users
        // Filterting out the duplicated and keep the most permissive ones
        var allUsersVaults = [Vault]()
        for userId in userIds {
            let vaults = try await shareRepository.getVaults(userId: userId)
            allUsersVaults.append(contentsOf: vaults)
        }
        let applicableVaults = allUsersVaults.deduplicated

        // Step 2: fetch all the items related to the applicable vaults
        var allUserItems = [SymmetricallyEncryptedItem]()
        for userId in userIds {
            let items = try await filterItems(userId: userId, applicableVaults: applicableVaults)
            allUserItems.append(contentsOf: items)
        }

        // Step 3: index the fetched items
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let credentials = try allUserItems.flatMap { try mapLoginItem(item: $0,
                                                                      symmetricKey: symmetricKey) }
        try await credentialManager.insert(credentials: credentials)

        let time = Date().timeIntervalSince1970 - start.timeIntervalSince1970
        let priority = Task.currentPriority.debugDescription
        let itemCount = "\(allUserItems.count) login items"
        let userCount = "\(userIds.count) users"
        let timeCount = "\(time) seconds with priority \(priority)"
        logger.info("Indexed \(itemCount) from \(userCount) in \(timeCount)")
    }
}

private extension IndexAllLoginItems {
    func filterItems(userId: String,
                     applicableVaults: [Vault]) async throws -> [SymmetricallyEncryptedItem] {
        guard let access = try await localAccessDatasource.getAccess(userId: userId) else {
            return []
        }
        let items = try await itemRepository.getActiveLogInItems(userId: userId)
        logger.trace("Found \(items.count) active login items")

        var vaults = try await shareRepository.getVaults(userId: userId)
        vaults = vaults.filter { applicableVaults.contains($0) }

        var applicableShareIds = [String]()
        if access.access.plan.isFreeUser {
            let oldestVaults = vaults.twoOldestVaults
            if let owned = oldestVaults.owned {
                applicableShareIds.append(owned.shareId)
            }
            if let other = oldestVaults.other {
                applicableShareIds.append(other.shareId)
            }
        } else {
            applicableShareIds = vaults.map(\.shareId)
        }

        return items.filter { applicableShareIds.contains($0.shareId) }
    }
}
