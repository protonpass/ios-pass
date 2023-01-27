//
// AppCoordinatorTests.swift
// Proton Pass - Created on 19/09/2022.
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

@testable import Proton_Pass
import ProtonCore_Authentication
import ProtonCore_Networking
import XCTest

final class AppCoordinatorTests: XCTestCase {
    var sut: AppCoordinator!

    override func setUp() {
        super.setUp()
        sut = .init(window: .init())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGetOrCreateSymmetricKey() throws {
        do {
            _ = try sut.getOrCreateSymmetricKey()
        } catch {
            XCTFail("Error getting or creating symmetric key \(error.localizedDescription)")
        }
    }
}
