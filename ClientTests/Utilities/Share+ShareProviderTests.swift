//
// Share+ShareProviderTests.swift
// Proton Pass - Created on 18/07/2022.
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
import ProtonCore_DataModel
import ProtonCore_Login
import XCTest

// swiftlint:disable function_body_length
final class SharePlusShareProviderTests: XCTestCase {
    func testGetVaultSuccess() throws {
        let vaultProtobuf = VaultProtobuf(name: .random(), note: .random())
        let testUser = UserData.test
        let addressKey = testUser.getAddressKey()
        let requestBody = try CreateVaultRequestBody(addressKey: addressKey,
                                                     vault: vaultProtobuf)

        let signingKeyPassphraseKeyPacketData =
        try XCTUnwrap(requestBody.signingKeyPassphraseKeyPacket.base64Decode())

        let signingKeyPassphraseData =
        try XCTUnwrap(requestBody.signingKeyPassphrase.base64Decode())

        let signingKeyPassphrase = signingKeyPassphraseKeyPacketData + signingKeyPassphraseData

        let createdShare =
        Share(shareID: .random(),
              vaultID: .random(),
              targetType: 0,
              targetID: .random(),
              permission: 0,
              acceptanceSignature: requestBody.acceptanceSignature,
              inviterEmail: testUser.user.email ?? "",
              inviterAcceptanceSignature: requestBody.acceptanceSignature,
              signingKey: requestBody.signingKey,
              signingKeyPassphrase: signingKeyPassphrase.base64EncodedString(),
              content: requestBody.content,
              contentRotationID: .random(),
              contentEncryptedAddressSignature: requestBody.contentEncryptedAddressSignature,
              contentEncryptedVaultSignature: requestBody.contentEncryptedVaultSignature,
              contentSignatureEmail: testUser.user.email ?? "",
              contentFormatVersion: 0,
              expireTime: nil,
              createTime: 0)

        let vaultKeyPassphraseKeyPacketData = try XCTUnwrap(requestBody.keyPacket.base64Decode())
        let vaultKeyPassphraseData = try XCTUnwrap(requestBody.vaultKeyPassphrase.base64Decode())
        let vaultKeyPassphrase = vaultKeyPassphraseKeyPacketData + vaultKeyPassphraseData

        let vaultKeys: [VaultKey] = [.init(rotationID: .random(),
                                           rotation: 0,
                                           key: requestBody.vaultKey,
                                           keyPassphrase: vaultKeyPassphrase.base64EncodedString(),
                                           keySignature: requestBody.vaultKeySignature,
                                           createTime: 0)]

        let vault = try createdShare.getVault(userData: testUser, vaultKeys: vaultKeys)

        XCTAssertEqual(vaultProtobuf.name, vault.name)
        XCTAssertEqual(vaultProtobuf.description_p, vault.description)
    }
}
