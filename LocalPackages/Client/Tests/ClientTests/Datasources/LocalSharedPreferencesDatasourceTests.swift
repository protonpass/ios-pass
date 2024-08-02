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
import TestingToolkit

final class LocalSharedPreferencesDatasourceTests: XCTestCase {
    var keychainMockProvider: KeychainProtocolMockProvider!
    var symmetricKeyProviderMockFactory: SymmetricKeyProviderMockFactory!
    var sut: LocalSharedPreferencesDatasourceProtocol!

    override func setUp() {
        super.setUp()
        keychainMockProvider = .init()
        keychainMockProvider.setUp()
        symmetricKeyProviderMockFactory = .init()
        symmetricKeyProviderMockFactory.setUp()
        sut = LocalSharedPreferencesDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                               keychain: keychainMockProvider.getKeychain())
    }

    override func tearDown() {
        keychainMockProvider = nil
        symmetricKeyProviderMockFactory = nil
        sut = nil
        super.tearDown()
    }
}

extension LocalSharedPreferencesDatasourceTests {
    func testGetAndUpsertPreferences() async throws {
        try await XCTAssertNilAsync(await sut.getPreferences())

        let givenPrefs = SharedPreferences.random()
        try await sut.upsertPreferences(givenPrefs)

        let result1 = try await XCTUnwrapAsync(await sut.getPreferences())
        XCTAssertEqual(result1, givenPrefs)

        let updatedPrefs = SharedPreferences.random()
        try await sut.upsertPreferences(updatedPrefs)
        let result2 = try await XCTUnwrapAsync(await sut.getPreferences())
        XCTAssertEqual(result2, updatedPrefs)

        try sut.removePreferences()
        try await XCTAssertNilAsync(await sut.getPreferences())
    }
}
