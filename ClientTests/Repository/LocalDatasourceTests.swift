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

final class LocalDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 10
    var sut: LocalDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(inMemory: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testFetchShares() throws {
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShares = (1...Int.random(in: 1...100)).map { _ in Share.random() }
            let givenUserId = String.random()

            // When
            try await sut.insertShares(givenShares, withUserId: givenUserId)
            // Populate the database with arbitrary shares
            // this is to test if fetching shares by userId correctly work
            for _ in 0...10 {
                try await sut.insertShares([.random()], withUserId: .random())
            }

            // Then
            let shares = try await sut.fetchShares(forUserId: givenUserId)
            let shareIds = Set(shares.map { $0.shareID })
            let givenShareIds = Set(givenShares.map { $0.shareID })
            if shareIds == givenShareIds {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
