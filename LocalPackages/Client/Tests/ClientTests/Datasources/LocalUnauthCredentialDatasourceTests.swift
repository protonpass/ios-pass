//
// LocalUnauthCredentialDatasourceTests.swift
// Proton Pass - Created on 12/06/2024.
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

@testable import Client
import Foundation
import ProtonCoreNetworking
import XCTest

final class LocalUnauthCredentialDatasourceTests: XCTestCase {
    var sut: LocalUnauthCredentialDatasourceProtocol!

    override func setUp() {
        super.setUp()
        let userDefaults = UserDefaults.standard
        userDefaults.removeAllObjects()
        sut = LocalUnauthCredentialDatasource(userDefault: userDefaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalUnauthCredentialDatasourceTests {
    func testGetAndUpsertCredential() throws {
        try XCTAssertNil(sut.getUnauthCredential())

        let givenCredential = AuthCredential.random()
        try sut.upsertUnauthCredential(givenCredential)

        let result1 = try XCTUnwrap(sut.getUnauthCredential())
        XCTAssertTrue(result1.isEqual(to: givenCredential))

        let updatedCredential = AuthCredential.random()
        try sut.upsertUnauthCredential(updatedCredential)
        let result2 = try XCTUnwrap(sut.getUnauthCredential())
        XCTAssertTrue(result2.isEqual(to: updatedCredential))

        sut.removeUnauthCredential()
        try XCTAssertNil(sut.getUnauthCredential())
    }
}
