//
// SessionManagerTests.swift
// Proton Pass - Created on 13/06/2024.
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
import ClientMocks
import CoreMocks
import Entities
import Foundation
import XCTest

final class SessionManagerTests: XCTestCase {
    var authDatasource: LocalAuthCredentialDatasourceProtocolMock!
    var unauthDatasource: LocalUnauthCredentialDatasourceProtocolMock!
    var preferencesManager: PreferencesManagerProtocol!
    var module: PassModule!
    var sut: SessionManagerProtocol!

    override func setUp() {
        super.setUp()
        authDatasource = .init()
        unauthDatasource = .init()
        module = .random()!
        sut = SessionManager(authDatasource: authDatasource,
                             unauthDatasource: unauthDatasource,
                             preferencesManager: preferencesManager,
                             module: module,
                             logManager: LogManagerProtocolMock())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension SessionManagerTests {
    func testDummy() {
        XCTAssertTrue(true)
    }
}
