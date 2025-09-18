//
// SymmetricallyEncryptedItem+Extensions.swift
// Proton Pass - Created on 24/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import CryptoKit
import Entities

public extension SymmetricallyEncryptedItem {
    /// Symmetrically decrypt and return decrypted item content
    func getItemContent(symmetricKey: SymmetricKey) throws -> ItemContent {
        let contentProtobuf = try ItemContentProtobuf(base64: encryptedContent, symmetricKey: symmetricKey)
        var simpleLoginNote: String?

        if let encryptedSimpleLoginNote,
           encryptedSimpleLoginNote != Constants.Database.encryptedSlNotePlaceholder {
            simpleLoginNote = try symmetricKey.decrypt(encryptedSimpleLoginNote)
        }

        return .init(userId: userId,
                     shareId: shareId,
                     item: item,
                     contentProtobuf: contentProtobuf,
                     simpleLoginNote: simpleLoginNote)
    }
}

public extension SymmetricallyEncryptedItem {
    func toItemUiModel(_ symmetricKey: SymmetricKey) throws -> ItemUiModel {
        let itemContent = try getItemContent(symmetricKey: symmetricKey)

        return itemContent.toItemUiModel
    }
}
