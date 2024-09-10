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
import Entities
import Foundation

public extension SymmetricKey {
    /// Encrypt a string into base64 format
    func encrypt(_ clearText: String) throws -> String {
        guard let data = clearText.data(using: .utf8) else {
            throw PassError.symmetricEncryption(.failedToUtf8ConvertToData(clearText))
        }
        let cypherData = try ChaChaPoly.seal(data, using: self).combined
        return cypherData.base64EncodedString()
    }

    func encrypt(_ clearData: Data) throws -> Data {
        try ChaChaPoly.seal(clearData, using: self).combined
    }

    /// Decrypt an encrypted base64 string
    func decrypt(_ cypherText: String) throws -> String {
        guard let data = Data(base64Encoded: cypherText) else {
            throw PassError.symmetricEncryption(.failedToBase64Decode(cypherText))
        }
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: self)
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: decryptedData, as: UTF8.self)
    }

    func decrypt(_ cypherData: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: cypherData)
        return try ChaChaPoly.open(sealedBox, using: self)
    }
}

extension SymmetricKey: @unchecked Sendable {}
