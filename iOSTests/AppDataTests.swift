//
// AppDataTests.swift
// Proton Pass - Created on 04/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Factory
import ProtonCoreLogin
import ProtonCoreNetworking
import XCTest

final class AppDataTests: XCTestCase {
    var keychainData: [String: Data] = [:]
    var keychain: KeychainMock!
    var mainKeyProvider: MainKeyProviderMock!
    var sut: AppData!

    override func setUp() {
        super.setUp()
        keychain = KeychainMock()
        keychain.setDataStub.bodyIs { _, data, key in
            self.keychainData[key] = data
        }
        keychain.dataStub.bodyIs { _, key in
            self.keychainData[key]
        }
        keychain.removeStub.bodyIs { _, key in
            self.keychainData[key] = nil
        }

        mainKeyProvider = MainKeyProviderMock()
        mainKeyProvider.mainKeyStub.fixture = Array(repeating: .zero, count: 32)
        Scope.singleton.reset()
        SharedToolingContainer.shared.keychain.register { self.keychain }
        SharedToolingContainer.shared.mainKeyProvider.register { self.mainKeyProvider }
        sut = AppData()
    }

    override func tearDown() {
        keychain = nil
        mainKeyProvider = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - UserData
extension AppDataTests {
    func testUserDataNilByDefault() {
        XCTAssertNil(sut.getUserData())
    }

    func testUpdateUserData() throws {
        // Given
        let givenUserData = UserData.mock

        // When
        sut.setUserData(givenUserData)

        // Then
        try XCTAssertEqual(sut.getUserId(), givenUserData.user.ID)

        // When
        sut.setUserData(nil)

        // Then
        XCTAssertNil(sut.getUserData())
    }
}

// MARK: - Unauth session credentials
extension AppDataTests {
    func testSessionCredentialsNilByDefault() {
        XCTAssertNil(sut.getCredential())
    }

    func testUpdateSessionCredentials() throws {
        // Given
        let givenCredentials = AuthCredential.preview

        // When
        sut.setCredentials(givenCredentials)

        // Then
        try XCTAssertEqual(sut.getCredential()?.sessionID, givenCredentials.sessionID)

        // When
        sut.setCredentials(nil)

        // Then
        XCTAssertNil(sut.getCredential())
    }
}

// MARK: - Symmetric key
extension AppDataTests {
    // Because we always randomize a new symmetric key when it's nil
    func testSymmetricKeyIsNeverNil() throws {
        try XCTAssertNotNil(sut.getSymmetricKey())

        // When
        sut.removeSymmetricKey()

        // Then
        try XCTAssertNotNil(sut.getSymmetricKey())
    }
}
