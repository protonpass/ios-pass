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

final class CreateVaultTests: XCTestCase {
    func testCreateVaultSuccess() throws {
        let (addressKey, addressKeyPassphrase) = try CryptoUtils.generateKey(name: "test", email: "test")
        let addressId = String.random(length: 10)
        let vaultName = String.random(length: 10)
        let key = Key(keyID: String.random(length: 10), privateKey: addressKey)
        let vault = try CreateVault.create(addressId: addressId,
                                           addressKey: key,
                                           passphrase: addressKeyPassphrase,
                                           vaultName: vaultName)
        XCTAssertEqual(vault.AddressID, addressId)
        let (armoredSigningKey, signingKeyPassphrase) =
        try validateSigningKey(addressKey: key,
                               addressKeyPassphrase: addressKeyPassphrase,
                               vault: vault)

        let signingKey = Key(keyID: String.random(length: 10), privateKey: armoredSigningKey)

        let (armoredVaultKey, vaultKeyPassphrase) =
        try validateVaultKey(addressKey: key,
                             addressKeyPassphrase: addressKeyPassphrase,
                             vault: vault,
                             signingKey: signingKey,
                             signingKeyPassphrase: signingKeyPassphrase)
        let vaultKey = Key(keyID: String.random(length: 10), privateKey: armoredVaultKey)
        try validateItemKey(vault: vault,
                            signingKey: signingKey,
                            signingKeyPassphrase: signingKeyPassphrase,
                            vaultKey: vaultKey,
                            vaultKeyPassphrase: vaultKeyPassphrase)
        try validateVaultData(vaultName: vaultName,
                              vault: vault,
                              vaultKey: vaultKey,
                              vaultKeyPassphrase: vaultKeyPassphrase)
    }

    func validateSigningKey(addressKey: Key,
                            addressKeyPassphrase: String,
                            vault: CreateVaultRequest) throws -> (signingKey: String,
                                                                  signingKeyPassphrase: String) {
        XCTAssertFalse(vault.SigningKeyPassphrase.isEmpty)
        XCTAssertFalse(vault.SigningKeyPassphraseKeyPacket.isEmpty)
        XCTAssertFalse(vault.SigningKey.isEmpty)
        let passphraseKeyPacket = try vault.SigningKeyPassphraseKeyPacket.base64Decode()
        let decodedPassphrase = try vault.SigningKeyPassphrase.base64Decode()
        var decryptSessionKeyError: NSError?
        let decryptedSessionKey = HelperDecryptSessionKey(addressKey.privateKey,
                                                          addressKeyPassphrase.data(using: .utf8),
                                                          passphraseKeyPacket,
                                                          &decryptSessionKeyError)
        let decryptedPassphrase = try decryptedSessionKey?.decrypt(decodedPassphrase)
        XCTAssertNil(decryptSessionKeyError)

        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: vault.SigningKey)
        let decodedAcceptanceSignature = try vault.AcceptanceSignature.base64Decode()

        var armorArmorWithTypeError: NSError?
        let armoredDecodedAcceptanceSignature = ArmorArmorWithType(decodedAcceptanceSignature,
                                                                   "SIGNATURE",
                                                                   &armorArmorWithTypeError)
        XCTAssertNil(armorArmorWithTypeError)
        XCTAssertTrue(try Crypto().verifyDetached(signature: armoredDecodedAcceptanceSignature,
                                                  plainData: Data(signingKeyFingerprint.utf8),
                                                  publicKey: addressKey.publicKey,
                                                  verifyTime: Int64(Date().timeIntervalSince1970)))

        return (vault.SigningKey, try XCTUnwrap(decryptedPassphrase).getString())
    }

    func validateVaultKey(addressKey: Key,
                          addressKeyPassphrase: String,
                          vault: CreateVaultRequest,
                          signingKey: Key,
                          signingKeyPassphrase: String) throws -> (vaultKey: String,
                                                                   vaultKeyPassphrase: String) {
        XCTAssertFalse(vault.VaultKeyPassphrase.isEmpty)
        XCTAssertFalse(vault.VaultKeySignature.isEmpty)
        XCTAssertFalse(vault.VaultKey.isEmpty)
        let passphraseKeyPacket = try vault.KeyPacket.base64Decode()
        let decodedPassphrase = try vault.VaultKeyPassphrase.base64Decode()
        var decryptSessionKeyError: NSError?
        let decryptedSessionKey = HelperDecryptSessionKey(addressKey.privateKey,
                                                          addressKeyPassphrase.data(using: .utf8),
                                                          passphraseKeyPacket,
                                                          &decryptSessionKeyError)
        let decryptedPassphrase = try decryptedSessionKey?.decrypt(decodedPassphrase)

        let vaultKeyFingerprint = try CryptoUtils.getFingerprint(key: vault.VaultKey)
        let decodedVaultKeySignature = try vault.VaultKeySignature.base64Decode()

        var armorArmorWithTypeError: NSError?
        let armoredDecodedVaultKeySignature = ArmorArmorWithType(decodedVaultKeySignature,
                                                                 "SIGNATURE",
                                                                 &armorArmorWithTypeError)
        XCTAssertNil(armorArmorWithTypeError)
        XCTAssertTrue(try Crypto().verifyDetached(signature: armoredDecodedVaultKeySignature,
                                                  plainData: Data(vaultKeyFingerprint.utf8),
                                                  publicKey: signingKey.publicKey,
                                                  verifyTime: Int64(Date().timeIntervalSince1970)))

        return (vault.VaultKey, try XCTUnwrap(decryptedPassphrase).getString())
    }

    func validateItemKey(vault: CreateVaultRequest,
                         signingKey: Key,
                         signingKeyPassphrase: String,
                         vaultKey: Key,
                         vaultKeyPassphrase: String) throws {
        XCTAssertFalse(vault.ItemKeyPassphrase.isEmpty)
        XCTAssertFalse(vault.ItemKeySignature.isEmpty)
        XCTAssertFalse(vault.ItemKey.isEmpty)
        let passphraseKeyPacket = try vault.ItemKeyPassphraseKeyPacket.base64Decode()
        let decodedPassphrase = try vault.ItemKeyPassphrase.base64Decode()
        var decryptSessionKeyError: NSError?
        let decryptedSessionKey = HelperDecryptSessionKey(vaultKey.privateKey,
                                                          vaultKeyPassphrase.data(using: .utf8),
                                                          passphraseKeyPacket,
                                                          &decryptSessionKeyError)
        // swiftlint:disable:next todo
        // TODO: Try to unlock item key
        let decryptedPassphrase = try decryptedSessionKey?.decrypt(decodedPassphrase)

        let itemKeyFingerprint = try CryptoUtils.getFingerprint(key: vault.ItemKey)
        let decodedItemKeySignature = try vault.ItemKeySignature.base64Decode()

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
                           vault: CreateVaultRequest,
                           vaultKey: Key,
                           vaultKeyPassphrase: String) throws {
        XCTAssertFalse(vault.Content.isEmpty)
        let decodedContent = try vault.Content.base64Decode()
        var error: NSError?
        let armoredContent = ArmorArmorWithType(decodedContent,
                                                "PGP MESSAGE",
                                                &error)
        let decryptedName = try Crypto().decrypt(encrypted: armoredContent,
                                                 privateKey: vaultKey.privateKey,
                                                 passphrase: vaultKeyPassphrase)
        XCTAssertEqual(vaultName, decryptedName)
    }
}
