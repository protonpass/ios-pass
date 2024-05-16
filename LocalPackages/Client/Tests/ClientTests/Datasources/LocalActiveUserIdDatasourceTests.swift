//
// LocalActiveUserIdDatasourceTests.swift
// Proton Pass - Created on 16/05/2024.
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
import XCTest

final class LocalActiveUserIdDatasourceTests: XCTestCase {
    var sut: LocalActiveUserIdDatasourceProtocol!

    override func setUp() {
        super.setUp()
        let userDefaults = UserDefaults.standard
        userDefaults.removeAllObjects()
        sut = LocalActiveUserIdDatasource(userDefault: userDefaults)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalActiveUserIdDatasourceTests {
    func testGetUpdateRemoveActiveUserId() {
        XCTAssertNil(sut.getActiveUserId())

        let id1 = String.random()
        sut.updateActiveUserId(id1)
        XCTAssertEqual(sut.getActiveUserId(), id1)

        let id2 = String.random()
        sut.updateActiveUserId(id2)
        XCTAssertEqual(sut.getActiveUserId(), id2)

        sut.removeActiveUserId()
        XCTAssertNil(sut.getActiveUserId())
    }
}
