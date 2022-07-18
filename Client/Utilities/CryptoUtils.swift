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
}

public enum CryptoUtils {
    public static func generateKey(name: String, email: String) throws -> (String, String) {
        let keyPassphrase = String.random(length: 32)
        var error: NSError?
        let key = HelperGenerateKey(name,
                                    email,
                                    Data(keyPassphrase.utf8),
                                    "x25519",
                                    0,
                                    &error)

        if let error = error { throw error }
        return (key, keyPassphrase)
    }

    public static func getFingerprint(key: String) throws -> String {
        var error: NSError?
        let data = HelperGetJsonSHA256Fingerprints(key, &error)
        if let error = error { throw error }
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
}

func unwrap<T>(caller: StaticString = #function, action: () -> T?) throws -> T {
    let optional = action()
    guard optional != nil else {
        throw NSError(domain: "Expected honest \(T.self), but found nil instead. \nCaller: \(caller)", code: 1)
    }
    return optional! // swiftlint:disable:this force_unwrapping
}
