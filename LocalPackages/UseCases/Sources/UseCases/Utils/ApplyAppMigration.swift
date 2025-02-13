//
//
// ApplyAppMigration.swift
// Proton Pass - Created on 28/06/2024.
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

public protocol ApplyAppMigrationUseCase: Sendable {
    func execute() async throws
}

public extension ApplyAppMigrationUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class ApplyAppMigration: ApplyAppMigrationUseCase {
    private let dataMigrationManager: any DataMigrationManagerProtocol
    private let userManager: any UserManagerProtocol
    private let appData: any AppDataProtocol
    private let authManager: any AuthManagerProtocol
    private let itemDatasource: any LocalItemDatasourceProtocol
    private let searchEntryDatasource: any LocalSearchEntryDatasourceProtocol
    private let shareKeyDatasource: any LocalShareKeyDatasourceProtocol
    private let logger: Logger

    public init(dataMigrationManager: any DataMigrationManagerProtocol,
                userManager: any UserManagerProtocol,
                appData: any AppDataProtocol,
                authManager: any AuthManagerProtocol,
                itemDatasource: any LocalItemDatasourceProtocol,
                searchEntryDatasource: any LocalSearchEntryDatasourceProtocol,
                shareKeyDatasource: any LocalShareKeyDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.dataMigrationManager = dataMigrationManager
        self.userManager = userManager
        self.appData = appData
        self.authManager = authManager
        self.itemDatasource = itemDatasource
        self.searchEntryDatasource = searchEntryDatasource
        self.shareKeyDatasource = shareKeyDatasource
        logger = .init(manager: logManager)
    }

    public func execute() async throws {
        logger.trace("Check if any migration should be applied to account")

        let missingMigrations = await dataMigrationManager.missingMigrations(MigrationType.all)

        logger.trace("The following migration are missing: \(missingMigrations)")

        if let userData = appData.getUserData(),
           missingMigrations.contains(.userAppData) ||
           missingMigrations.contains(.credentialsForActionExtension) {
            logger
                .trace("Starting user data migration for app data to user manager for user id : \(userData.user.ID)")
            try await userManager.upsertAndMarkAsActive(userData: userData)
            if let credential = appData.getMainCredential() {
                (authManager as? AuthManager)?.migrate(credential)
            }
            appData.resetData()
            logger.trace("User data migration done for user id : \(userData.user.ID)")
            await dataMigrationManager.addMigration(.userAppData)
        }

        if missingMigrations.contains(.userIdInItemsSearchEntriesAndShareKeys) {
            guard let userId = try? await userManager.getActiveUserId() else {
                logger.debug("Skip user ID migrations. No active user ID found.")
                await dataMigrationManager.addMigration(.userIdInItemsSearchEntriesAndShareKeys)
                return
            }

            logger.trace("Start adding user id to items, search entries & share keys")
            async let items: ()? = (itemDatasource as? LocalItemDatasource)?.updateLocalItems(with: userId)
            async let searchEntries: ()? = (searchEntryDatasource as? LocalSearchEntryDatasource)?
                .updateSearchEntries(with: userId)
            async let shareKeys: ()? = (shareKeyDatasource as? LocalShareKeyDatasource)?.updateKeys(with: userId)
            _ = try await (items, searchEntries, shareKeys)
            logger.trace("Finish adding user id to items, search entries & share keys")

            await dataMigrationManager.addMigration(.userIdInItemsSearchEntriesAndShareKeys)
        }
    }
}
