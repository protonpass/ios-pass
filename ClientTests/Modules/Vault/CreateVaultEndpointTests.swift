//
// CreateVaultEndpointTests.swift
// Proton Pass - Created on 11/07/2022.
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

@testable import Client
import Core
import XCTest

final class CreateVaultEndpointTests: XCTestCase {
    func testCreateVaultEndpoint() throws {
        let baseURL = try XCTUnwrap(URL(string: "https://example.com"))
        let credential = MockClientCredential.random
        let createVaultRequest = CreateVaultRequest(addressID: .random(),
                                                    content: .random(),
                                                    contentFormatVersion: .random(in: 0...100),
                                                    contentEncryptedAddressSignature: .random(),
                                                    contentEncryptedVaultSignature: .random(),
                                                    vaultKey: .random(),
                                                    vaultKeyPassphrase: .random(),
                                                    vaultKeySignature: .random(),
                                                    keyPacket: .random(),
                                                    keyPacketSignature: .random(),
                                                    signingKey: .random(),
                                                    signingKeyPassphrase: .random(),
                                                    signingKeyPassphraseKeyPacket: .random(),
                                                    acceptanceSignature: .random(),
                                                    itemKey: .random(),
                                                    itemKeyPassphrase: .random(),
                                                    itemKeyPassphraseKeyPacket: .random(),
                                                    itemKeySignature: .random())
        let bodyData = try JSONEncoder().encode(createVaultRequest)
        let sut = CreateVaultEndpoint(baseURL: baseURL,
                                      credential: credential,
                                      createVaultRequest: createVaultRequest)

        XCTAssertEqual(sut.request.httpMethod, "POST")
        XCTAssertEqual(sut.request.url?.absoluteString, "https://example.com/pass/v1/vault")
        XCTAssertEqual(sut.request.allHTTPHeaderFields?["Authorization"], "Bearer \(credential.accessToken)")
        XCTAssertEqual(sut.request.allHTTPHeaderFields?["x-pm-uid"], credential.uid)
        XCTAssertEqual(sut.request.httpBody, bodyData)
    }
}
