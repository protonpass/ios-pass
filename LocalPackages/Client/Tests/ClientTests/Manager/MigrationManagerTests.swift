//
// MigrationManagerTests.swift
// Proton Pass - Created on 21/06/2024.
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

@testable import Client
import ClientMocks
import Entities
import Testing

@Suite(.tags(.manager))
struct MigrationManagerTests {
    private let sut: any DataMigrationManagerProtocol =
        DataMigrationManager(datasource: LocalDataMigrationDatasourceProtocolMock())

    @Test func `every migration is missing when none was added`() async {
        let missingMigration = await sut.missingMigrations(MigrationType.all)
        #expect(missingMigration == MigrationType.all)
    }

    @Test func `an added migration is no longer missing`() async {
        await sut.addMigration(.userAppData)
        let userAppDataMigrationDone = await sut.hasMigrationOccurred(.userAppData)
        let missingMigration = await sut.missingMigrations(MigrationType.all)

        #expect(userAppDataMigrationDone)
        #expect(missingMigration == [MigrationType.credentialsAppData,
                                     MigrationType.credentialsForActionExtension])
    }

    @Test func `a reverted migration is missing again`() async {
        await sut.addMigration(.userAppData)
        let userAppDataMigrationDone = await sut.hasMigrationOccurred(.userAppData)
        #expect(userAppDataMigrationDone)

        await sut.revertMigration(.userAppData)
        let userAppDataMigrationUnDone = await sut.hasMigrationOccurred(.userAppData)

        let missingMigration = await sut.missingMigrations(MigrationType.all)

        #expect(!userAppDataMigrationUnDone)
        #expect(missingMigration == MigrationType.all)
    }
}
