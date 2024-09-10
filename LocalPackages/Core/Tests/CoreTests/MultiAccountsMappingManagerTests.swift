//
// MultiAccountsMappingManagerTests.swift
// Proton Pass - Created on 10/09/2024.
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
//

@testable import Core
import Entities
import XCTest

final class MultiAccountsMappingManagerTests: XCTestCase {
    var sut: MultiAccountsMappingManager!

    private struct Item: ItemIdentifiable {
        let shareId: String
        let itemId: String

        static func random() -> Item {
            .init(shareId: .random(), itemId: .random())
        }
    }

    override func setUp() {
        super.setUp()
        sut = MultiAccountsMappingManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension MultiAccountsMappingManagerTests {
    func testGetVaultIdWithFailure() {
        let expectation = XCTestExpectation(description: "Should fail")
        // Given
        sut.add([.random()], userId: .random())

        do {
            // When
            _ = try sut.getVaultId(for: .random())
        } catch {
            // Then
            if let passError = error as? PassError {
                switch passError {
                case let .vault(reason):
                    if case .vaultNotFound = reason {
                        expectation.fulfill()
                    }
                default:
                    break
                }
            }
        }
        wait(for: [expectation])
    }

    func testGetVaultIdWithSuccess() throws {
        // Given
        let vault = Vault.random()
        sut.add([vault], userId: .random())
        sut.add([vault, .random(), .random()], userId: .random())

        // When
        let firstGet = try sut.getVaultId(for: vault.shareId)

        // Then
        XCTAssertFalse(firstGet.cached)
        XCTAssertEqual(firstGet.object, vault.id)

        // When
        let secondGet = try sut.getVaultId(for: vault.shareId)

        // Then
        XCTAssertTrue(secondGet.cached)
        XCTAssertEqual(secondGet.object, vault.id)
    }

    func testGetUserWithFailure() {
        let expectation = XCTestExpectation(description: "Should fail")
        // Given
        let item = Item.random()
        sut.add([.random()])

        do {
            // When
            _ = try sut.getUser(for: item)
        } catch {
            // Then
            if let passError = error as? PassError {
                switch passError {
                case let .userManager(reason):
                    if case let .noUserFound(shareId, itemId) = reason,
                       shareId == item.shareId,
                       itemId == item.itemId {
                        expectation.fulfill()
                    }
                default:
                    break
                }
            }
        }
        wait(for: [expectation])
    }

    func testGetUserWithSuccess() throws {
        // Given
        let vault = Vault.random()
        let item = Item(shareId: vault.shareId, itemId: .random())
        let user = PassUser.random()
        sut.add([user])
        sut.add([vault], userId: user.id)

        // When
        let firstGet = try sut.getUser(for: item)

        // Then
        XCTAssertFalse(firstGet.cached)
        XCTAssertEqual(firstGet.object, user)

        // When
        let secondGet = try sut.getUser(for: item)

        // Then
        XCTAssertTrue(secondGet.cached)
        XCTAssertEqual(secondGet.object, user)
    }
}
