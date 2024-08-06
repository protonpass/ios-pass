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
import XCTest

final class SymmetricKeyProviderTests: XCTestCase {
    var keychainProvider: KeychainProtocolMockProvider!
    var mainKeyProvider: MainKeyProviderMock!
    var sut: SymmetricKeyProvider!

    override func setUp() {
        super.setUp()
        injectDefaultCryptoImplementation()
        keychainProvider = .init()
        keychainProvider.setUp()

        mainKeyProvider = .init()
        mainKeyProvider.stubbedMainKey = Array(repeating: .zero, count: 32)

        sut = SymmetricKeyProviderImpl(keychain: keychainProvider.getKeychain(),
                                       mainKeyProvider: mainKeyProvider)
    }

    override func tearDown() {
        keychainProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension SymmetricKeyProviderTests {
    func testKeyGeneration() async throws {
        let key1 = try await sut.getSymmetricKey()
        let key2 = try await sut.getSymmetricKey()
        let key3 = try await sut.getSymmetricKey()
        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1, key3)
        XCTAssertEqual(key2, key3)
    }
}
