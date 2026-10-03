//
// SymmetricKeyProviderTests.swift
// Proton Pass - Created on 05/04/2024.
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
import CoreMocks
import ProtonCoreCryptoGoImplementation
import Testing

@Suite(.tags(.manager))
struct SymmetricKeyProviderTests {
    /// `static` so the global crypto implementation is installed exactly once.
    private static let cryptoIsInstalled: Bool = {
        injectDefaultCryptoImplementation()
        return true
    }()

    private let sut: any SymmetricKeyProvider

    init() {
        _ = Self.cryptoIsInstalled

        let keychainProvider = KeychainProtocolMockProvider()
        keychainProvider.setUp()

        let mainKeyProvider = MainKeyProviderMock()
        mainKeyProvider.stubbedMainKey = Array(repeating: .zero, count: 32)

        sut = SymmetricKeyProviderImpl(keychain: keychainProvider.getKeychain(),
                                       mainKeyProvider: mainKeyProvider)
    }

    @Test func `the same symmetric key is returned on every call`() async throws {
        let key1 = try await sut.getSymmetricKey()
        let key2 = try await sut.getSymmetricKey()
        let key3 = try await sut.getSymmetricKey()
        #expect(key1 == key2)
        #expect(key1 == key3)
        #expect(key2 == key3)
    }
}
