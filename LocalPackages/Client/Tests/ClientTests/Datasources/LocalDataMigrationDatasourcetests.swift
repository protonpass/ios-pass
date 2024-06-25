//  
// LocalMigrationsDatasourcetests.swift
// Proton Pass - Created on 25/06/2024.
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
import Entities
import XCTest

final class LocalDataMigrationDatasourceTests: XCTestCase {
    var sut: LocalDataMigrationDatasourceProtocol!

    override func setUp() {
        super.setUp()
        let userDefaults = UserDefaults.standard
        userDefaults.removeAllObjects()
        sut = LocalDataMigrationDatasource(userDefault: userDefaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalDataMigrationDatasourceTests {
    func testGetUpdateRemoveActiveUserId() async throws {
        let noMigration = try await sut.getMigrations()
        XCTAssertNil(noMigration)

        try await sut.upsert(migrations: MigrationStatus(completedMigrations: 0))
        let migration1 = try await XCTUnwrapAsync(try await sut.getMigrations())
        XCTAssertEqual(migration1.completedMigrations, 0)

        try await sut.upsert(migrations: MigrationStatus(completedMigrations: 1))

        let migration2 = try await XCTUnwrapAsync(try await sut.getMigrations())

        XCTAssertEqual(migration2.completedMigrations, 1)
    }
}

