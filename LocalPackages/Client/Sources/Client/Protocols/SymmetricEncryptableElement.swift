//
// SymmetricEncryptableElement.swift
// Proton Pass - Created on 09/12/2025.
// Copyright (c) 2025 Proton Technologies AG
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

protocol SymmetricEncryptableElement {
    /// Initialize from binary data
    init(data: Data) throws
    init(base64: String, symmetricKey: SymmetricKey) throws

    func data() throws -> Data
    /// Symmetrically encrypt and base 64 the binary data
    func encrypt(symmetricKey: SymmetricKey) throws -> String
}

extension SymmetricEncryptableElement {
    /// Symmetrically encrypt and base 64 the binary data
    func encrypt(symmetricKey: SymmetricKey) throws -> String {
        let clearData = try data()
        let cypherData = try symmetricKey.encrypt(clearData)
        return cypherData.base64EncodedString()
    }

    init(base64: String, symmetricKey: SymmetricKey) throws {
        guard let cypherData = base64.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }
        let clearData = try symmetricKey.decrypt(cypherData)
        try self.init(data: clearData)
    }
}
