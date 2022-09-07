//
// LocalShareKeysDatasourceTests.swift
// Proton Pass - Created on 16/08/2022.
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
import CoreData
import XCTest

final class LocalShareKeysDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 3
    var sut: LocalShareKeysDatasource!

    override func setUp() {
        super.setUp()
        let container = NSPersistentContainer.Builder.build(name: kProtonPassContainerName,
                                                            inMemory: true)
        let localItemKeyDatasource = LocalItemKeyDatasource(container: container)
        let localVaultKeyDatasource = LocalVaultKeyDatasource(container: container)
        sut = .init(localItemKeyDatasource: localItemKeyDatasource,
                    localVaultKeyDatasource: localVaultKeyDatasource)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalShareKeysDatasourceTests {
    func testThrowErrorWhenItemKeyCountDiffersVaultKeyCount() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let givenItemKeys = [ItemKey].random(count: 123, randomElement: .random())
            let givenVaultKeys = [VaultKey].random(count: 456, randomElement: .random())

            // When
            try await sut.localItemKeyDatasource.upsertItemKeys(givenItemKeys,
                                                                shareId: givenShareId)
            try await sut.localVaultKeyDatasource.upsertVaultKeys(givenVaultKeys,
                                                                  shareId: givenShareId)
            // Then
            do {
                _ = try await sut.getShareKeys(shareId: givenShareId, page: 0, pageSize: .max)
            } catch {
                if let localDatasourceError = error as? LocalDatasourceError {
                    switch localDatasourceError {
                    case .corruptedShareKeys:
                        expectation.fulfill()
                    default:
                        break
                    }
                }
            }
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testGetShareKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let givenKeyCount = Int.random(in: 10...100)
            let givenItemKeys = [ItemKey].random(count: givenKeyCount,
                                                 randomElement: .random())
            let givenVaultKeys = [VaultKey].random(count: givenKeyCount,
                                                   randomElement: .random())

            // When
            try await sut.localItemKeyDatasource.upsertItemKeys(givenItemKeys,
                                                                shareId: givenShareId)
            try await sut.localVaultKeyDatasource.upsertVaultKeys(givenVaultKeys,
                                                                  shareId: givenShareId)
            // Then
            let shareKeys = try await sut.getShareKeys(shareId: givenShareId,
                                                       page: 0,
                                                       pageSize: givenKeyCount)
            XCTAssertEqual(shareKeys.total, givenKeyCount)
            XCTAssertEqual(shareKeys.itemKeys.count, givenKeyCount)
            XCTAssertEqual(shareKeys.vaultKeys.count, givenKeyCount)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
