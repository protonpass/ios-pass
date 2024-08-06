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
    func execute(userId: String) async throws
}

public extension IndexAllLoginItemsUseCase {
    func callAsFunction(userId: String) async throws {
        try await execute(userId: userId)
    }
}

public final class IndexAllLoginItems: @unchecked Sendable, IndexAllLoginItemsUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let credentialManager: any CredentialManagerProtocol
    private let mapLoginItem: any MapLoginItemUseCase
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let logger: Logger

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                credentialManager: any CredentialManagerProtocol,
                mapLoginItem: any MapLoginItemUseCase,
                symmetricKeyProvider: any SymmetricKeyProvider,
                logManager: any LogManagerProtocol) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.accessRepository = accessRepository
        self.credentialManager = credentialManager
        self.mapLoginItem = mapLoginItem
        self.symmetricKeyProvider = symmetricKeyProvider
        logger = .init(manager: logManager)
    }

    // swiftlint:disable:next todo
    // TODO: Will have to accept the credential of several accounts and not just one
    // will either have to take list of ids or not remove previous credentials
    public func execute(userId: String) async throws {
        let start = Date()
        logger.trace("Indexing all login items")

        guard await credentialManager.isAutoFillEnabled else {
            logger.trace("Skipped indexing all login items. AutoFill not enabled")
            return
        }

        try await credentialManager.removeAllCredentials()
        let items = try await filterItems(userId: userId)

        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let credentials = try items.flatMap { try mapLoginItem(item: $0, symmetricKey: symmetricKey) }
        try await credentialManager.insert(credentials: credentials)

        let time = Date().timeIntervalSince1970 - start.timeIntervalSince1970
        let priority = Task.currentPriority.debugDescription
        logger.info("Indexed \(items.count) login items in \(time) seconds with priority \(priority)")
    }
}

private extension IndexAllLoginItems {
    func filterItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        let plan = try await accessRepository.getPlan()
        let items = try await itemRepository.getActiveLogInItems(userId: userId)
        logger.trace("Found \(items.count) active login items")
        if !plan.isFreeUser {
            return items
        }
        let vaults = try await shareRepository.getVaults(userId: userId)
        let oldestVaults = vaults.twoOldestVaults
        return items.filter { oldestVaults.isOneOf(shareId: $0.shareId) }
    }
}
