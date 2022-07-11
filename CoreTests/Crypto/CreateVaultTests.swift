//
// CreateVaultTests.swift
// Proton Pass - Created on 08/07/2022.
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

@testable import Core
import Crypto
import ProtonCore_Crypto
import ProtonCore_DataModel
import XCTest

// swiftlint:disable function_parameter_count
final class CreateVaultTests: XCTestCase {
    func testCreateVaultSuccess() throws {
        let (addressKey, addressKeyPassphrase) = try CryptoUtils.generateKey(name: "test", email: "test")
        let addressId = String.random()
        let vaultName = String.random()
        let vaultDescription = String.random()
        var vault = VaultProtobuf()
        vault.name = vaultName
        vault.description_p = vaultDescription
        let key = Key(keyID: String.random(), privateKey: addressKey)
        let createVaultRequest = try CreateVault.create(addressId: addressId,
                                                        addressKey: key,
                                                        passphrase: addressKeyPassphrase,
                                                        vault: vault)
        XCTAssertEqual(createVaultRequest.addressID, addressId)
        let (armoredSigningKey, signingKeyPassphrase) =
        try validateSigningKey(addressKey: key,
                               addressKeyPassphrase: addressKeyPassphrase,
                               createVaultRequest: createVaultRequest)

        let signingKey = Key(keyID: String.random(), privateKey: armoredSigningKey)

        let (armoredVaultKey, vaultKeyPassphrase) =
        try validateVaultKey(addressKey: key,
                             addressKeyPassphrase: addressKeyPassphrase,
                             createVaultRequest: createVaultRequest,
                             signingKey: signingKey,
                             signingKeyPassphrase: signingKeyPassphrase)
        let vaultKey = Key(keyID: String.random(), privateKey: armoredVaultKey)
        try validateItemKey(createVaultRequest: createVaultRequest,
                            signingKey: signingKey,
                            signingKeyPassphrase: signingKeyPassphrase,
                            vaultKey: vaultKey,
                            vaultKeyPassphrase: vaultKeyPassphrase)
        try validateVaultData(vaultName: vaultName,
                              vaultDescription: vaultDescription,
                              vaultType: type(of: vault),
                              createVaultRequest: createVaultRequest,
                              vaultKey: vaultKey,
                              vaultKeyPassphrase: vaultKeyPassphrase)
    }

    func validateSigningKey(addressKey: Key,
                            addressKeyPassphrase: String,
                            createVaultRequest: CreateVaultRequest) throws -> (signingKey: String,
                                                                  signingKeyPassphrase: String) {
        XCTAssertFalse(createVaultRequest.signingKeyPassphrase.isEmpty)
        XCTAssertFalse(createVaultRequest.signingKeyPassphraseKeyPacket.isEmpty)
        XCTAssertFalse(createVaultRequest.signingKey.isEmpty)
        let passphraseKeyPacket = try createVaultRequest.signingKeyPassphraseKeyPacket.base64Decode()
        let decodedPassphrase = try createVaultRequest.signingKeyPassphrase.base64Decode()
        var decryptSessionKeyError: NSError?
        let decryptedSessionKey = HelperDecryptSessionKey(addressKey.privateKey,
                                                          addressKeyPassphrase.data(using: .utf8),
                                                          passphraseKeyPacket,
                                                          &decryptSessionKeyError)
        let decryptedPassphrase = try decryptedSessionKey?.decrypt(decodedPassphrase)
        XCTAssertNil(decryptSessionKeyError)

        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: createVaultRequest.signingKey)
        let decodedAcceptanceSignature = try createVaultRequest.acceptanceSignature.base64Decode()

        var armorArmorWithTypeError: NSError?
        let armoredDecodedAcceptanceSignature = ArmorArmorWithType(decodedAcceptanceSignature,
                                                                   "SIGNATURE",
                                                                   &armorArmorWithTypeError)
        XCTAssertNil(armorArmorWithTypeError)
        XCTAssertTrue(try Crypto().verifyDetached(signature: armoredDecodedAcceptanceSignature,
                                                  plainData: Data(signingKeyFingerprint.utf8),
                                                  publicKey: addressKey.publicKey,
                                                  verifyTime: Int64(Date().timeIntervalSince1970)))

        return (createVaultRequest.signingKey, try XCTUnwrap(decryptedPassphrase).getString())
    }

    func validateVaultKey(addressKey: Key,
                          addressKeyPassphrase: String,
                          createVaultRequest: CreateVaultRequest,
                          signingKey: Key,
                          signingKeyPassphrase: String) throws -> (vaultKey: String,
                                                                   vaultKeyPassphrase: String) {
        XCTAssertFalse(createVaultRequest.vaultKeyPassphrase.isEmpty)
        XCTAssertFalse(createVaultRequest.vaultKeySignature.isEmpty)
        XCTAssertFalse(createVaultRequest.vaultKey.isEmpty)
        let passphraseKeyPacket = try createVaultRequest.keyPacket.base64Decode()
        let decodedPassphrase = try createVaultRequest.vaultKeyPassphrase.base64Decode()
        var decryptSessionKeyError: NSError?
        let decryptedSessionKey = HelperDecryptSessionKey(addressKey.privateKey,
                                                          addressKeyPassphrase.data(using: .utf8),
                                                          passphraseKeyPacket,
                                                          &decryptSessionKeyError)
        let decryptedPassphrase = try decryptedSessionKey?.decrypt(decodedPassphrase)

        let vaultKeyFingerprint = try CryptoUtils.getFingerprint(key: createVaultRequest.vaultKey)
        let decodedVaultKeySignature = try createVaultRequest.vaultKeySignature.base64Decode()

        var armorArmorWithTypeError: NSError?
        let armoredDecodedVaultKeySignature = ArmorArmorWithType(decodedVaultKeySignature,
                                                                 "SIGNATURE",
                                                                 &armorArmorWithTypeError)
        XCTAssertNil(armorArmorWithTypeError)
        XCTAssertTrue(try Crypto().verifyDetached(signature: armoredDecodedVaultKeySignature,
                                                  plainData: Data(vaultKeyFingerprint.utf8),
                                                  publicKey: signingKey.publicKey,
                                                  verifyTime: Int64(Date().timeIntervalSince1970)))

        return (createVaultRequest.vaultKey, try XCTUnwrap(decryptedPassphrase).getString())
    }

    func validateItemKey(createVaultRequest: CreateVaultRequest,
                         signingKey: Key,
                         signingKeyPassphrase: String,
                         vaultKey: Key,
                         vaultKeyPassphrase: String) throws {
        XCTAssertFalse(createVaultRequest.itemKeyPassphrase.isEmpty)
        XCTAssertFalse(createVaultRequest.itemKeySignature.isEmpty)
        XCTAssertFalse(createVaultRequest.itemKey.isEmpty)
        let passphraseKeyPacket = try createVaultRequest.itemKeyPassphraseKeyPacket.base64Decode()
        let decodedPassphrase = try createVaultRequest.itemKeyPassphrase.base64Decode()
        var decryptSessionKeyError: NSError?
        let decryptedSessionKey = HelperDecryptSessionKey(vaultKey.privateKey,
                                                          vaultKeyPassphrase.data(using: .utf8),
                                                          passphraseKeyPacket,
                                                          &decryptSessionKeyError)
        // swiftlint:disable:next todo
        // TODO: Try to unlock item key
        let decryptedPassphrase = try decryptedSessionKey?.decrypt(decodedPassphrase)

        let itemKeyFingerprint = try CryptoUtils.getFingerprint(key: createVaultRequest.itemKey)
        let decodedItemKeySignature = try createVaultRequest.itemKeySignature.base64Decode()

        var armorArmorWithTypeError: NSError?
        let armoredDecodedItemKeySignature = ArmorArmorWithType(decodedItemKeySignature,
                                                                "SIGNATURE",
                                                                &armorArmorWithTypeError)
        XCTAssertNil(armorArmorWithTypeError)
        XCTAssertTrue(try Crypto().verifyDetached(signature: armoredDecodedItemKeySignature,
                                                  plainData: Data(itemKeyFingerprint.utf8),
                                                  publicKey: signingKey.publicKey,
                                                  verifyTime: Int64(Date().timeIntervalSince1970)))
    }

    func validateVaultData(vaultName: String,
                           vaultDescription: String,
                           vaultType: VaultProvider.Type,
                           createVaultRequest: CreateVaultRequest,
                           vaultKey: Key,
                           vaultKeyPassphrase: String) throws {
        XCTAssertFalse(createVaultRequest.content.isEmpty)
        let decodedContent = try createVaultRequest.content.base64Decode()
        var error: NSError?
        let armoredContent = ArmorArmorWithType(decodedContent,
                                                "PGP MESSAGE",
                                                &error)
        let decryptedVaultBase64 = try Crypto().decrypt(encrypted: armoredContent,
                                                        privateKey: vaultKey.privateKey,
                                                        passphrase: vaultKeyPassphrase)
        let vaultData = try XCTUnwrap(decryptedVaultBase64.base64Decode())
        let vault = try vaultType.init(data: vaultData)
        XCTAssertEqual(vault.name, vaultName)
        XCTAssertEqual(vault.description, vaultDescription)
    }
}
