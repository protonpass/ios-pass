//  
// LocalDataMigrationDatasourceTests.swift
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
import Foundation
import Testing

@Suite(.tags(.localDatasource))
final class LocalDataMigrationDatasourceTests {
    private let suiteName = "LocalDataMigrationDatasourceTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let sut: any LocalDataMigrationDatasourceProtocol

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        sut = LocalDataMigrationDatasource(userDefault: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func `migration status defaults to zero and reflects the last upsert`() async {
        #expect(await sut.getMigrations() == 0)

        await sut.upsert(migrations: 0)
        #expect(await sut.getMigrations() == 0)

        await sut.upsert(migrations: 1)
        #expect(await sut.getMigrations() == 1)
    }
}
