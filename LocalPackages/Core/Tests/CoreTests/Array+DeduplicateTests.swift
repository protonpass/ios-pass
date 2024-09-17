//
// Array+DeduplicateTests.swift
// Proton Pass - Created on 11/09/2024.
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
import XCTest

final class ArrayDeduplicateTests: XCTestCase {
    struct Vault: Equatable {
        let shareId: String
        let vaultId: String
    }

    func testDeduplication() {
        // Given
        let vault1 = Vault(shareId: "share1", vaultId: "vault1")
        let vault2 = Vault(shareId: "share1", vaultId: "vault2")
        let vault3 = Vault(shareId: "share2", vaultId: "vault3")
        let vault4 = Vault(shareId: "share2", vaultId: "vault4")
        let vault5 = Vault(shareId: "share3", vaultId: "vault5")

        let sut = [vault1, vault2, vault3, vault4, vault5]

        // When
        let result = sut.deduplicate(by: \.shareId)

        // Then
        XCTAssertEqual(result, [vault1, vault3, vault5])
    }
}
