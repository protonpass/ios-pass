//
// SymmetricKey+ChaChaPoly.swift
// Proton Pass - Created on 20/09/2022.
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

import CryptoKit

public enum SymmetricEncryptionError: Error {
    case failedToUtf8ConvertToData(String)
    case failedToBase64Decode(String)
    case failedToUtf8Decode(Data)
}

public extension SymmetricKey {
    /// Encrypt a string into base64 format
    func encrypt(_ clearText: String) throws -> String {
        guard let data = clearText.data(using: .utf8) else {
            throw SymmetricEncryptionError.failedToUtf8ConvertToData(clearText)
        }
        let cypherData = try ChaChaPoly.seal(data, using: self).combined
        return cypherData.base64EncodedString()
    }

    /// Decrypt an encrypted base64 string
    func decrypt(_ cypherText: String) throws -> String {
        guard let data = Data(base64Encoded: cypherText) else {
            throw SymmetricEncryptionError.failedToBase64Decode(cypherText)
        }
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: self)

        guard let clearText = String(data: decryptedData, encoding: .utf8) else {
            throw SymmetricEncryptionError.failedToUtf8Decode(decryptedData)
        }
        return clearText
    }
}

public protocol SymmetricallyEncryptable {
    func symmetricallyEncrypted(_ symmetricKey: SymmetricKey) throws -> Self
    func symmetricallyDecrypted(_ symmetricKey: SymmetricKey) throws -> Self
}
