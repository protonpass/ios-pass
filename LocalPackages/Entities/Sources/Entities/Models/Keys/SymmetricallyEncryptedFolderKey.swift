//
// SymmetricallyEncryptedFolderKey.swift
// Proton Pass - Created on 02/02/2026.
// Copyright (c) 2026 Proton Technologies AG
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

public struct SymmetricallyEncryptedFolderKey: Hashable, Sendable {
    public let shareId: String
    /// Base64 representation of the symmetrically encrypted folder key
    public let encryptedKey: String
    /// ID of the folder that the key belongs to
    public let folderId: String
    /// The user ID of the folder key
    public let userId: String
    public let keyRotation: Int64

    public init(shareId: String, encryptedKey: String, folderId: String, userId: String, keyRotation: Int64) {
        self.shareId = shareId
        self.encryptedKey = encryptedKey
        self.folderId = folderId
        self.userId = userId
        self.keyRotation = keyRotation
    }
}

extension SymmetricallyEncryptedFolderKey: SymmetricallyEncryptedKeyTypeProtocol {
    public var id: String {
        folderId
    }

    public func buildKey(with decryptedKeyData: Data) -> any CryptographicKeyProtocol {
        DecryptedFolderKey(shareId: shareId,
                           folderId: folderId,
                           keyRotation: keyRotation,
                           keyData: decryptedKeyData)
    }
}
