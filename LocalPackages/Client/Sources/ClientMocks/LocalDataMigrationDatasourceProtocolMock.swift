// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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
//
//import Client
//import Foundation
//import CoreData
//import Entities
//
//public final class LocalDataMigrationDatasourceProtocolMock: @unchecked Sendable, LocalDataMigrationDatasourceProtocol {
//
//    public init() {}
//
//    // MARK: - getMigrations
//    public var getMigrationsThrowableError1: Error?
//    public var closureGetMigrations: () -> () = {}
//    public var invokedGetMigrationsfunction = false
//    public var invokedGetMigrationsCount = 0
//    public var stubbedGetMigrationsResult: MigrationStatus?
//
//    public func getMigrations() async throws -> MigrationStatus? {
//        invokedGetMigrationsfunction = true
//        invokedGetMigrationsCount += 1
//        if let error = getMigrationsThrowableError1 {
//            throw error
//        }
//        closureGetMigrations()
//        return stubbedGetMigrationsResult
//    }
//    // MARK: - upsert
//    public var upsertMigrationsThrowableError2: Error?
//    public var closureUpsert: () -> () = {}
//    public var invokedUpsertfunction = false
//    public var invokedUpsertCount = 0
//    public var invokedUpsertParameters: (migrations: MigrationStatus, Void)?
//    public var invokedUpsertParametersList = [(migrations: MigrationStatus, Void)]()
//
//    public func upsert(migrations: MigrationStatus) async throws {
//        invokedUpsertfunction = true
//        invokedUpsertCount += 1
//        invokedUpsertParameters = (migrations, ())
//        invokedUpsertParametersList.append((migrations, ()))
//        if let error = upsertMigrationsThrowableError2 {
//            throw error
//        }
//        closureUpsert()
//    }
//}
