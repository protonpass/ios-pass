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
    private let itemRepository: any ItemRepositoryProtocol

    public init(dataMigrationManager: any DataMigrationManagerProtocol,
                userManager: any UserManagerProtocol,
                appData: any AppDataProtocol,
                itemRepository: any ItemRepositoryProtocol) {
        self.dataMigrationManager = dataMigrationManager
        self.userManager = userManager
        self.appData = appData
        self.itemRepository = itemRepository
    }

    public func execute() async throws {
        let missingMigrations = await dataMigrationManager.missingMigrations(MigrationType.all)

        if let userData = appData.getUserData(), missingMigrations.contains(.userAppData) {
            try await userManager.addAndMarkAsActive(userData: userData)
            await dataMigrationManager.addMigration(.userAppData)
        }

        if missingMigrations.contains(.userIdInItems) {
            try await itemRepository.updateLocalItemsWithUserId()
            await dataMigrationManager.addMigration(.userIdInItems)
        }
    }
}
