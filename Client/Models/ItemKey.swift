//
// ItemKey.swift
// Proton Pass - Created on 19/07/2022.
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

import Foundation

public struct ItemKey: Codable {
    public let rotationID: String

    /// Armored item key
    public let key: String

    /// Base64 encoded passphrase to unlock the vault private key. Only for vault shares.
    /// Encrypted with the user's address key.
    public let keyPassphrase: String?

    /// Base64 encoded signature for the key fingerprint. Signed with the signing key
    public let keySignature: String

    /// Creation time of the key
    public let createTime: Int64

    public init(rotationID: String,
                key: String,
                keyPassphrase: String?,
                keySignature: String,
                createTime: Int64) {
        self.rotationID = rotationID
        self.key = key
        self.keyPassphrase = keyPassphrase
        self.keySignature = keySignature
        self.createTime = createTime
    }
}
