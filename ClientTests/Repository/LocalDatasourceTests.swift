//
// LocalDatasourceTests.swift
// Proton Pass - Created on 03/08/2022.
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

@testable import Client
import XCTest

/*
These tests aim to ensure the local database reads and writes data correctly.
Each entity has in general these test cases:
 - Insert test: ensure write operations
 - Fetch test: ensure read & write operations
 - Update test: ensure data is not duplicated but updated
 base on the uniqueness constrainted in the xcdatamodeld
 */

final class LocalDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 3
    var sut: LocalDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(inMemory: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    /// Create and insert a random share
    func givenInsertedShare(withUserId userId: String? = nil) async throws -> Share {
        let share = Share.random()
        try await sut.insertShares([share], withUserId: userId ?? .random())
        return share
    }
}
