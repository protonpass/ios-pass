//
// CreateItemRequestBody.swift
// Proton Pass - Created on 09/08/2022.
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

public struct CreateItemRequestBody: Encodable {
    /// Encrypted ID of the VaultKey used to create this item
    public let rotationID: String

    /// Pairs of labelId:labelKeyPacket
    public let labels: [ItemLabelKeyPacket]

    /// VaultKeyPacket encoded in Base64
    public let vaultKeyPacket: String

    /// Base64 encoded signature for the vault keypacket
    public let vaultKeyPacketSignature: String

    /// Version of the content format used to create the item
    public let contentFormatVersion: Int16

    /// Encrypted item content encoded in Base64
    public let content: String

    /// Contents signature by the user address key encrypted with the same session key
    /// as the contents encoded in base64
    public let userSignature: String

    /// Contents signature by the item key encrypted with the same session key
    /// as the contents encoded in base64
    public let itemKeySignature: String

    public init(rotationID: String,
                labels: [ItemLabelKeyPacket],
                vaultKeyPacket: String,
                vaultKeyPacketSignature: String,
                contentFormatVersion: Int16,
                content: String,
                userSignature: String,
                itemKeySignature: String) {
        self.rotationID = rotationID
        self.labels = labels
        self.vaultKeyPacket = vaultKeyPacket
        self.vaultKeyPacketSignature = vaultKeyPacketSignature
        self.contentFormatVersion = contentFormatVersion
        self.content = content
        self.userSignature = userSignature
        self.itemKeySignature = itemKeySignature
    }

    public init(item: ProtobufableItemProtocol) throws {
        self.init(rotationID: .random(),
                  labels: [],
                  vaultKeyPacket: .random(),
                  vaultKeyPacketSignature: .random(),
                  contentFormatVersion: 0,
                  content: .random(),
                  userSignature: .random(),
                  itemKeySignature: .random())
    }
}
