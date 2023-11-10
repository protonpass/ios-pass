//
// LocalPublicKeyDatasourceTests.swift
// Proton Pass - Created on 17/08/2022.
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

import Client
import Entities
import XCTest

final class LocalPublicKeyDatasourceTests: XCTestCase {
    var sut: LocalPublicKeyDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalPublicKeyDatasourceTests {
    func testInsertAndGetPublicKeys() async throws {
        // Given
        let givenEmail1 = String.random()
        let givenPublicKeys1 = [PublicKey].random(randomElement: .random())
        let givenEmail2 = String.random()
        let givenPublicKeys2 = [PublicKey].random(randomElement: .random())

        // When
        try await sut.insertPublicKeys(givenPublicKeys1, email: givenEmail1)
        try await sut.insertPublicKeys(givenPublicKeys2, email: givenEmail2)

        // Then
        let publicKeys1 = try await sut.getPublicKeys(email: givenEmail1)
        XCTAssertEqual(Set(publicKeys1.map(\.value)),
                       Set(givenPublicKeys1.map(\.value)))

        let publicKeys2 = try await sut.getPublicKeys(email: givenEmail2)
        XCTAssertEqual(Set(publicKeys2.map(\.value)),
                       Set(givenPublicKeys2.map(\.value)))
    }
}
