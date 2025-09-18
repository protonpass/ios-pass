//
// DataMigrationManager.swift
// Proton Pass - Created on 20/06/2024.
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

// periphery:ignore:all
import Foundation

public struct MigrationType: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let userAppData = MigrationType(rawValue: 1 << 0)
    public static let credentialsAppData = MigrationType(rawValue: 1 << 1)

    // Obsolete and removed in September 2025 but we keep it for the record
    public static let userIdInItemsSearchEntriesAndShareKeys = MigrationType(rawValue: 1 << 2)

    public static let credentialsForActionExtension = MigrationType(rawValue: 1 << 3)
    public static let all: [MigrationType] = [
        .userAppData,
        .credentialsAppData,
        .credentialsForActionExtension
    ]
}

public protocol DataMigrationManagerProtocol: Sendable {
    func addMigration(_ migration: MigrationType) async
    func hasMigrationOccurred(_ migration: MigrationType) async -> Bool
    func missingMigrations(_ migrations: [MigrationType]) async -> [MigrationType]
    func revertMigration(_ migration: MigrationType) async
}

public actor DataMigrationManager: DataMigrationManagerProtocol {
    private let datasource: any LocalDataMigrationDatasourceProtocol

    public init(datasource: any LocalDataMigrationDatasourceProtocol) {
        self.datasource = datasource
    }

    public func addMigration(_ migration: MigrationType) async {
        var status = await datasource.getMigrations()

        status |= migration.rawValue

        await datasource.upsert(migrations: status)
    }

    public func hasMigrationOccurred(_ migration: MigrationType) async -> Bool {
        let status = await datasource.getMigrations()

        return status & migration.rawValue == migration.rawValue
    }

    public func missingMigrations(_ migrations: [MigrationType]) async -> [MigrationType] {
        let status = await datasource.getMigrations()

        return migrations.filter { (status & $0.rawValue) != $0.rawValue }
    }

    public func revertMigration(_ migration: MigrationType) async {
        var status = await datasource.getMigrations()
        status &= ~migration.rawValue

        await datasource.upsert(migrations: status)
    }
}
