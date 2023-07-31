//
// CredentialManager.swift
// Proton Pass - Created on 04/10/2022.
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

import AuthenticationServices
import Core

public protocol CredentialManagerProtocol {
    var store: ASCredentialIdentityStore { get }
    var logger: Logger { get }

    /// Whether users had choosen Proton Pass as AutoFill Provider
    func isAutoFillEnabled() async -> Bool

    func insert(credentials: [AutoFillCredential]) async throws
    func remove(credentials: [AutoFillCredential]) async throws

    /// Get all active login items from `ItemRepository` and insert to credential store
    /// - Parameter itemRepository: The `ItemRepository` to get items
    /// - Parameter shareRepository: The `ShareRepository` to get all vaults
    /// - Parameter passPlanRepository: The `PassPlanRepository` to get the current plan
    /// - Parameter forceRemoval: If `true`, will remove all credentials before inserting.
    /// if `false`, only insert when no credentials found in credential store
    func insertAllCredentials(itemRepository: ItemRepositoryProtocol,
                              shareRepository: ShareRepositoryProtocol,
                              passPlanRepository: PassPlanRepositoryProtocol,
                              forceRemoval: Bool) async throws
    func removeAllCredentials() async throws
}

public extension CredentialManagerProtocol {
    func isAutoFillEnabled() async -> Bool {
        await store.state().isEnabled
    }

    func insert(credentials: [AutoFillCredential]) async throws {
        logger.trace("Trying to insert \(credentials.count) credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped inserting \(credentials.count) credentials.")
            return
        }

        let domainCredentials = try credentials.map { try ASPasswordCredentialIdentity($0) }

        if state.supportsIncrementalUpdates {
            logger.trace("Non empty credential store. Inserting \(credentials.count) credentials.")
            try await store.saveCredentialIdentities(domainCredentials)
        } else {
            logger.trace("Empty credential store. Inserting \(credentials.count) credentials.")
            try await store.replaceCredentialIdentities(with: domainCredentials)
        }
        logger.trace("Inserted \(credentials.count) credentials.")
    }

    func remove(credentials: [AutoFillCredential]) async throws {
        logger.trace("Trying to remove \(credentials.count) credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped removing \(credentials.count) credentials.")
            return
        }

        let domainCredentials = try credentials.map { try ASPasswordCredentialIdentity($0) }

        if state.supportsIncrementalUpdates {
            logger.trace("Removing \(credentials.count) credentials.")
            try await store.removeCredentialIdentities(domainCredentials)
            logger.trace("Removed \(credentials.count) credentials.")
        } else {
            logger.trace("Empty store. Skipped removing \(credentials.count) credentials.")
        }
    }

    func insertAllCredentials(itemRepository: ItemRepositoryProtocol,
                              shareRepository: ShareRepositoryProtocol,
                              passPlanRepository: PassPlanRepositoryProtocol,
                              forceRemoval: Bool) async throws {
        logger.trace("Trying to insert all credentials from ItemRepository")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped inserting all credentials from ItemRepository")
            return
        }

        if forceRemoval {
            logger.trace("Force removing all credentials before inserting new ones")
            try await removeAllCredentials()
        } else if state.supportsIncrementalUpdates {
            logger.trace("Credentials exist. Skipped inserting all credentials.")
            return
        }

        let vaults = try await shareRepository.getVaults()
        let plan = try await passPlanRepository.getPlan()

        let symmetricKey = itemRepository.symmetricKey
        let encryptedItems = try await itemRepository.getActiveLogInItems()
        var credentials = [AutoFillCredential]()
        for encryptedItem in encryptedItems {
            let vault = vaults.first { $0.shareId == encryptedItem.shareId }

            let shouldTakeIntoAccount: Bool
            switch plan.planType {
            case .free:
                shouldTakeIntoAccount = vault?.isPrimary == true
            default:
                shouldTakeIntoAccount = true
            }

            // Do not suggest items in non-primary vaults when in free plan
            guard shouldTakeIntoAccount else { continue }

            let itemContent = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
            if case let .login(data) = itemContent.contentData {
                // A login item can have multiple associated URLs while the OS expects a single URL per item,
                // so we need to make a separate entry for each URL in the credential database.
                for url in data.urls {
                    credentials.append(.init(shareId: itemContent.shareId,
                                             itemId: itemContent.item.itemID,
                                             username: data.username,
                                             url: url,
                                             lastUseTime: itemContent.item.lastUseTime ?? 0))
                }
            }
        }
        try await insert(credentials: credentials)
    }

    func removeAllCredentials() async throws {
        logger.trace("Removing all credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped removing all credentials.")
            return
        }

        try await store.removeAllCredentialIdentities()
        logger.trace("Removed all credentials.")
    }
}

public final class CredentialManager: CredentialManagerProtocol {
    public var store: ASCredentialIdentityStore
    public var logger: Logger

    public init(logManager: LogManagerProtocol,
                store: ASCredentialIdentityStore = .shared) {
        self.store = store
        logger = .init(manager: logManager)
    }
}

extension CredentialManager: ItemRepositoryDelegate {
    public func itemRepositoryHasNewCredentials(_ credentials: [AutoFillCredential]) {
        Task {
            do {
                logger.trace("Inserting \(credentials.count) new credentials")
                try await insert(credentials: credentials)
                logger.trace("Inserted \(credentials.count) new credentials")
            } catch {
                logger.error(error)
            }
        }
    }

    public func itemRepositoryDeletedCredentials(_ credentials: [AutoFillCredential]) {
        Task {
            do {
                logger.trace("Removing \(credentials.count) deleted credentials")
                try await remove(credentials: credentials)
                logger.info("Removed \(credentials.count) deleted credentials")
            } catch {
                logger.error(error)
            }
        }
    }
}
