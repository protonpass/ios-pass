//
// ShareProvider.swift
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

import Core
import Crypto
import ProtonCore_Crypto
import ProtonCore_KeyManager
import ProtonCore_Login

public protocol ShareProvider: Identifiable {
    var id: String { get }

    func getVault(userData: UserData) throws -> VaultProvider
}

extension Share: ShareProvider {
    public var id: String { self.shareID }

    public func getVault(userData: UserData) throws -> VaultProvider {
        let signingKeyValid = try validateSigningKey(userData: userData)
        return Vault(id: UUID().uuidString, name: .random(), description: .random())
    }

    private func validateSigningKey(userData: UserData) throws -> Bool {
        guard let firstAddress = userData.addresses.first else {
            assertionFailure("Address can not be nil")
            throw CryptoError.failedToEncrypt
        }
        let addressKeys = try firstAddress.keys.compactMap { key -> DecryptionKey? in
            guard let binKey = userData.user.keys.first?.privateKey.unArmor else { return nil }
            let passphrase = try key.passphrase(userBinKeys: [binKey],
                                                mailboxPassphrase: userData.passphrases.first?.value ?? "")
            return DecryptionKey(privateKey: key.privateKey, passphrase: passphrase)
        }
        let privateKeyRing = try Decryptor.buildPrivateKeyRing(with: addressKeys)

        // Here we have decrypted signing key but it's not used yet
        let decryptedSigningKeyPassphrase =
        try privateKeyRing.decrypt(.init(try signingKeyPassphrase?.base64Decode()),
                                   verifyKey: nil,
                                   verifyTime: 0)
        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: signingKey)
        let decodedAcceptanceSignature = try acceptanceSignature.base64Decode()

        var armorArmorWithTypeError: NSError?
        let armoredDecodedAcceptanceSignature = ArmorArmorWithType(decodedAcceptanceSignature,
                                                                   "SIGNATURE",
                                                                   &armorArmorWithTypeError)

        if let armorArmorWithTypeError = armorArmorWithTypeError {
            throw armorArmorWithTypeError
        }

        // swiftlint:disable:next todo
        // TODO: Should pass server time
        try privateKeyRing.verifyDetached(.init(Data(signingKeyFingerprint.utf8)),
                                          signature: .init(fromArmored: armoredDecodedAcceptanceSignature),
                                          verifyTime: Int64(Date().timeIntervalSince1970))
        return true
    }

//    private func validateVaultKey(userData: UserData) throws -> Bool {
//        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: vault)
//        let decodedAcceptanceSignature = try acceptanceSignature.base64Decode()
//
//        var armorArmorWithTypeError: NSError?
//        let armoredDecodedAcceptanceSignature = ArmorArmorWithType(decodedAcceptanceSignature,
//                                                                   "SIGNATURE",
//                                                                   &armorArmorWithTypeError)
//
//        if let armorArmorWithTypeError = armorArmorWithTypeError {
//            throw armorArmorWithTypeError
//        }
//
//        // swiftlint:disable:next todo
//        // TODO: Should pass server time
//        try privateKeyRing.verifyDetached(.init(Data(signingKeyFingerprint.utf8)),
//                                          signature: .init(fromArmored: armoredDecodedAcceptanceSignature),
//                                          verifyTime: Int64(Date().timeIntervalSince1970))
//    }
}
