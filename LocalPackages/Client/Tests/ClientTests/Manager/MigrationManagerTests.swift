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
import XCTest

final class MigrationManagerTests: XCTestCase {
    var migrationDatasource: LocalDataMigrationDatasourceProtocol!
    var sut: DataMigrationManagerProtocol!

    override func setUp() {
        super.setUp()

        migrationDatasource = LocalDataMigrationDatasourceProtocolMock()
        sut = DataMigrationManager(datasource: migrationDatasource)
    }

    override func tearDown() {
        sut = nil
        migrationDatasource = nil
        super.tearDown()
    }

    func testNoMigrationSet() async {
        let missingMigration = await sut.missingMigrations(MigrationType.all)
        XCTAssertEqual(missingMigration, MigrationType.all)
    }

    func testAddOneMigration() async {
        await sut.addMigration(.userAppData)
        let userAppDataMigrationDone =  await sut.hasMigrationOccurred(.userAppData)
        let missingMigration =  await sut.missingMigrations(MigrationType.all)

        XCTAssertTrue(userAppDataMigrationDone)
        XCTAssertEqual(missingMigration,
                       [MigrationType.credentialsAppData,
                        MigrationType.credentialsForActionExtension])
    }

    func testRevertAMigration() async {
        await sut.addMigration(.userAppData)
        let userAppDataMigrationDone = await sut.hasMigrationOccurred(.userAppData)
        XCTAssertTrue(userAppDataMigrationDone)

        await sut.revertMigration(.userAppData)
        let userAppDataMigrationUnDone = await sut.hasMigrationOccurred(.userAppData)

        let missingMigration = await sut.missingMigrations(MigrationType.all)

        XCTAssertFalse(userAppDataMigrationUnDone)
        XCTAssertEqual(missingMigration, MigrationType.all)
    }
}
