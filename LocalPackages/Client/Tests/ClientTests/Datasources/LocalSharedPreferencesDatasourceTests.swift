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
import Testing
import TestingToolkit

@Suite(.tags(.localDatasource))
struct LocalSharedPreferencesDatasourceTests {
    let sut: any LocalSharedPreferencesDatasourceProtocol

    init() {
        let keychainMockProvider = KeychainProtocolMockProvider()
        keychainMockProvider.setUp()
        let symmetricKeyProviderMockFactory = SymmetricKeyProviderMockFactory()
        symmetricKeyProviderMockFactory.setUp()
        sut = LocalSharedPreferencesDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                               keychain: keychainMockProvider.getKeychain())
    }

    @Test func `preferences can be upserted, updated and removed`() async throws {
        #expect(try await sut.getPreferences() == nil)

        let givenPrefs = SharedPreferences.random()
        try await sut.upsertPreferences(givenPrefs)

        let result1 = try #require(await sut.getPreferences())
        #expect(result1 == givenPrefs)

        let updatedPrefs = SharedPreferences.random()
        try await sut.upsertPreferences(updatedPrefs)
        let result2 = try #require(await sut.getPreferences())
        #expect(result2 == updatedPrefs)

        try sut.removePreferences()
        #expect(try await sut.getPreferences() == nil)
    }
}
