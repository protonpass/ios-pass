//
// AutoFillCredential.swift
// Proton Pass - Created on 28/09/2022.
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

import AuthenticationServices
import Core
import Entities

/// A proxy object for `ASPasswordCredentialIdentity` to interact with the credential database
public struct AutoFillCredential: Sendable {
    /// A combination of `shareId` and `itemId` of an item to make up an unique ID
    public struct IDs: CodableBase64, ItemIdentifiable, Sendable {
        public let shareId: String
        public let itemId: String
    }

    /// Maps the `recordIdentifier` property
    let ids: IDs
    /// Maps the `user` property
    let username: String
    /// Maps the `serviceIdentifier` property
    let url: String
    /// Maps the `rank` property
    let lastUseTime: Int64
}

public extension AutoFillCredential {
    init(shareId: String,
         itemId: String,
         username: String,
         url: String,
         lastUseTime: Int64) {
        ids = .init(shareId: shareId, itemId: itemId)
        self.username = username
        self.url = url
        self.lastUseTime = lastUseTime
    }
}
