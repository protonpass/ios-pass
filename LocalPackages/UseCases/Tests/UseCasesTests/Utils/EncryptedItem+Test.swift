//
// EncryptedItem+Test.swift
// Proton Pass - Created on 05/10/2026.
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

import Client
import CryptoKit
import Entities
import EntitiesMocks
import Foundation

/// Builds a `SymmetricallyEncryptedItem` whose content really decrypts with `key`, unlike
/// `SymmetricallyEncryptedItem.random()` which uses a random ciphertext.
func makeEncryptedItem(shareId: String = "share-1",
                       folderId: String? = nil,
                       item: Item = .random(state: .active, flags: 0),
                       name: String = "Name",
                       data: ItemContentData,
                       key: SymmetricKey) throws -> SymmetricallyEncryptedItem {
    let content = ItemContentProtobuf(name: name, note: "", itemUuid: .random(), data: data, customFields: [])
    return try SymmetricallyEncryptedItem(shareId: shareId,
                                          userId: "user-1",
                                          folderId: folderId,
                                          item: item,
                                          encryptedContent: key.encrypt(content.data()).base64EncodedString(),
                                          isLogInItem: data.type == .login,
                                          encryptedSimpleLoginNote: nil)
}
