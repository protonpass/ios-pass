//
//
// RecreateSecureLink.swift
// Proton Pass - Created on 13/06/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Client
import CryptoKit
import Entities

public protocol RecreateSecureLinkUseCase: Sendable {
    func execute(for link: SecureLink, itemContent: ItemContent) async throws -> String
}

public extension RecreateSecureLinkUseCase {
    func callAsFunction(for link: SecureLink, itemContent: ItemContent) async throws -> String {
        try await execute(for: link, itemContent: itemContent)
    }
}

public final class RecreateSecureLink: RecreateSecureLinkUseCase {
    private let passKeyManager: any PassKeyManagerProtocol
    private let userManager: any UserManagerProtocol

    public init(passKeyManager: any PassKeyManagerProtocol,
                userManager: any UserManagerProtocol) {
        self.passKeyManager = passKeyManager
        self.userManager = userManager
    }

    public func execute(for link: SecureLink, itemContent: ItemContent) async throws -> String {
        let userId = try await userManager.getActiveUserId()
        let shareKey: any ShareKeyProtocol = if link.linkKeyEncryptedWithItemKey {
            if itemContent.item.itemKey == nil {
                try await passKeyManager.getShareKey(userId: userId,
                                                     shareId: link.shareID,
                                                     keyRotation: link.linkKeyShareKeyRotation)
            } else {
                try await passKeyManager.getItemKey(userId: userId,
                                                    shareId: link.shareID,
                                                    itemId: link.itemID,
                                                    keyRotation: link.linkKeyShareKeyRotation)
            }
        } else {
            try await passKeyManager.getShareKey(userId: userId,
                                                 shareId: link.shareID,
                                                 keyRotation: link.linkKeyShareKeyRotation)
        }

        guard let linkKeyData = try link.encryptedLinkKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedLinkKeyData = try AES.GCM.open(linkKeyData,
                                                    key: shareKey.keyData,
                                                    associatedData: .linkKey)

        return "\(link.linkURL)#\(decryptedLinkKeyData.base64URLSafeEncodedString())"
    }
}
