//
// LocalDatasourceTests+fetchShareKey.swift
// Proton Pass - Created on 05/08/2022.
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

extension LocalDatasourceTests {
    func testFetchShareKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let keypairCount = 10
            let givenVaultKeys = [VaultKey].random(count: keypairCount,
                                                   randomElement: .random())
            let givenItemKeys = [ItemKey].random(count: keypairCount,
                                                 randomElement: .random())

            // When
            try await sut.insertVaultKeys(givenVaultKeys, withShareId: givenShareId)
            try await sut.insertItemKeys(givenItemKeys, withShareId: givenShareId)

            // Then
            // swiftlint:disable:next todo
            // TODO: Post MVP test pagination
            let shareKey = try await sut.fetchShareKey(forShareId: givenShareId,
                                                       page: 0,
                                                       pageSize: Int.max)
            XCTAssertEqual(shareKey.total, keypairCount)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
