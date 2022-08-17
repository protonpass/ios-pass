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

final class SharePlusShareProviderTests: XCTestCase {
    func testGetVaultSuccess() throws {
        let vaultProtobuf = VaultProtobuf(name: .random(), note: .random())
        let testUser = UserData.test
        let addressKey = testUser.getAddressKey()
        let request = try CreateVaultRequest(addressKey: addressKey, vault: vaultProtobuf)

        let signingKeyPassphraseKeyPacketData =
        try XCTUnwrap(request.signingKeyPassphraseKeyPacket.base64Decode())

        let signingKeyPassphraseData =
        try XCTUnwrap(request.signingKeyPassphrase.base64Decode())

        let signingKeyPassphrase = signingKeyPassphraseKeyPacketData + signingKeyPassphraseData

        let createdShare =
        Share(shareID: .random(),
              vaultID: .random(),
              targetType: 0,
              targetID: .random(),
              permission: 0,
              acceptanceSignature: request.acceptanceSignature,
              inviterEmail: testUser.user.email ?? "",
              inviterAcceptanceSignature: request.acceptanceSignature,
              signingKey: request.signingKey,
              signingKeyPassphrase: signingKeyPassphrase.base64EncodedString(),
              content: request.content,
              contentRotationID: .random(),
              contentEncryptedAddressSignature: request.contentEncryptedAddressSignature,
              contentEncryptedVaultSignature: request.contentEncryptedVaultSignature,
              contentSignatureEmail: testUser.user.email ?? "",
              contentFormatVersion: 0,
              expireTime: nil,
              createTime: 0)

        let vaultKeyPassphraseKeyPacketData = try XCTUnwrap(request.keyPacket.base64Decode())
        let vaultKeyPassphraseData = try XCTUnwrap(request.vaultKeyPassphrase.base64Decode())
        let vaultKeyPassphrase = vaultKeyPassphraseKeyPacketData + vaultKeyPassphraseData

        let vaultKeys: [VaultKey] = [.init(rotationID: .random(),
                                           rotation: 0,
                                           key: request.vaultKey,
                                           keyPassphrase: vaultKeyPassphrase.base64EncodedString(),
                                           keySignature: request.vaultKeySignature,
                                           createTime: 0)]

        let vault = try createdShare.getVault(userData: testUser, vaultKeys: vaultKeys)

        XCTAssertEqual(vaultProtobuf.name, vault.name)
        XCTAssertEqual(vaultProtobuf.description_p, vault.description)
    }
}
