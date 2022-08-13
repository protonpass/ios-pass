//
// ItemRevision.swift
// Proton Pass - Created on 13/08/2022.
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

public struct ItemRevisionList: Decodable {
    let total: Int
    let revisionsData: [ItemRevision]
}

public struct ItemRevision: Decodable {
    public let itemID: String
    public let revision: Int16
    public let contentFormatVersion: Int16

    /// Parent key ID to whom the key packet belongs
    public let rotationID: String

    /// Base64 encoded item contents including the key packet
    public let content: String

    /// Base64 encoded item contents encrypted signature made with the user's address key
    public let userSignature: String

    /// Base64 encoded item contents encrypted signature made with the vault's item key
    public let itemKeySignature: String

    /// Revision state
    public let state: Int16

    /// Email address of the signer
    public let signatureEmail: String

    /// In case this item contains an alias, this is the email address for the alias
    public let aliasEmail: String?

    // Post MVP
    //    public let labels: [String]

    /// Creation time of the item
    public let createTime: Int64

    /// Time of last update of the item
    public let modifyTime: Int64
}
