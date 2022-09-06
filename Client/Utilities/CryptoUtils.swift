//
// CryptoUtils.swift
// Proton Pass - Created on 12/07/2022.
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

public enum CryptoError: Error {
    case failedToSplitPGPMessage
    case failedToUnarmor(String)
    case failedToGetFingerprint
    case failedToGenerateKeyRing
    case failedToEncrypt
    case failedToVerifyVault
    case failedToDecryptContent
    case failedToVerifySignature
    case failedToGenerateSessionKey
    case failedToDecode
}

public enum CryptoUtils {
    public static func generateKey(name: String, email: String) throws -> (String, String) {
        let keyPassphrase = String.random(length: 32)
        let key = try throwing { error in
            HelperGenerateKey(name,
                              email,
                              Data(keyPassphrase.utf8),
                              "x25519",
                              0,
                              &error)
        }
        return (key, keyPassphrase)
    }

    public static func getFingerprint(key: String) throws -> String {
        let data = try throwing { error in
            HelperGetJsonSHA256Fingerprints(key, &error)
        }
        guard let data = data else {
            throw CryptoError.failedToGetFingerprint
        }
        let array = try JSONDecoder().decode([String].self, from: data)
        guard let fingerprint = array.first else {
            throw CryptoError.failedToGetFingerprint
        }
        return fingerprint
    }

    public static func splitPGPMessage(_ message: String) throws -> (keyPacket: Data, dataPacket: Data) {
        let splitMessage = try unwrap { CryptoPGPSplitMessage(fromArmored: message) }
        guard let keyPacket = splitMessage.keyPacket,
              let dataPacket = splitMessage.dataPacket else {
            throw CryptoError.failedToSplitPGPMessage
        }
        return (keyPacket, dataPacket)
    }

    public static func unarmorAndBase64(data: String, name: String) throws -> String {
        guard let unarmoredData = data.unArmor else {
            throw CryptoError.failedToUnarmor(name)
        }
        return unarmoredData.base64EncodedString()
    }

    public static func armorSignature(_ signature: Data) throws -> String {
        try throwing { error in
            ArmorArmorWithType(signature, "SIGNATURE", &error)
        }
    }

    public static func armorMessage(_ message: Data) throws -> String {
        try throwing { error in
            ArmorArmorWithType(message, "MESSAGE", &error)
        }
    }

    public static func generateSessionKey() throws -> CryptoSessionKey {
        var error: NSError?
        guard let sessionKey = CryptoGenerateSessionKey(&error) else {
            throw CryptoError.failedToGenerateSessionKey
        }
        if let error = error { throw error }
        return sessionKey
    }
}
