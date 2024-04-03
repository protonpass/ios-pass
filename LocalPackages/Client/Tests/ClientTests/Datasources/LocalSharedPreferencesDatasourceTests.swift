//
// LocalSharedPreferencesDatasourceTests.swift
// Proton Pass - Created on 03/04/2024.
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
import Core
import CoreMocks
import CryptoKit
import Entities
import Foundation
import XCTest

final class LocalSharedPreferencesDatasourceTests: XCTestCase {
    var keychainData: [String: Data] = [:]
    var keychain: KeychainProtocolMock!
    var symmetricKey = SymmetricKey.random()
    var symmetricKeyProvider: SymmetricKeyProvider!
    var sut: LocalSharedPreferencesDatasourceProtocol!

    override func setUp() {
        super.setUp()
        keychain = KeychainProtocolMock()

        keychain.closureSetOrErrorDataKeyAttributes3 = {
            if let data = self.keychain.invokedSetOrErrorDataKeyAttributesParameters3?.0,
               let key = self.keychain.invokedSetOrErrorDataKeyAttributesParameters3?.1 {
                self.keychainData[key] = data
            }
        }

        keychain.closureDataOrError = {
            if let key = self.keychain.invokedDataOrErrorParameters?.0 {
                self.keychain.stubbedDataOrErrorResult = self.keychainData[key]
            }
        }

        keychain.closureRemoveOrError = {
            if let key = self.keychain.invokedRemoveOrErrorParameters?.0 {
                self.keychainData[key] = nil
            }
        }

        let symmetricKeyProvider = SymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = symmetricKey
        self.symmetricKeyProvider = symmetricKeyProvider
        sut = LocalSharedPreferencesDatasource(symmetricKeyProvider: symmetricKeyProvider,
                                               keychain: keychain)
    }

    override func tearDown() {
        keychainData = [:]
        keychain = nil
        symmetricKeyProvider = nil
        symmetricKey = .random()
        sut = nil
        super.tearDown()
    }
}

extension LocalSharedPreferencesDatasourceTests {
    func testGetAndUpsertPreferences() throws {
        try XCTAssertNil(sut.getPreferences())

        let givenPrefs = SharedPreferences.random()
        try sut.upsertPreferences(givenPrefs)

        let result1 = try XCTUnwrap(sut.getPreferences())
        XCTAssertEqual(result1, givenPrefs)

        let updatedPrefs = SharedPreferences.random()
        try sut.upsertPreferences(updatedPrefs)
        let result2 = try XCTUnwrap(sut.getPreferences())
        XCTAssertEqual(result2, updatedPrefs)

        try sut.removePreferences()
        try XCTAssertNil(sut.getPreferences())
    }
}
