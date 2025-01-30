//
// GetSecureLinkKeys.swift
// Proton Pass - Created on 16/05/2024.
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
import Core
import CryptoKit
import Entities
import Foundation

public protocol GetSecureLinkKeysUseCase: Sendable {
    func execute(item: ItemContent, share: Share, encryptedWithItemKey: Bool) async throws -> SecureLinkKeys
}

public extension GetSecureLinkKeysUseCase {
    func callAsFunction(item: ItemContent,
                        share: Share,
                        encryptedWithItemKey: Bool) async throws -> SecureLinkKeys {
        try await execute(item: item, share: share, encryptedWithItemKey: encryptedWithItemKey)
    }
}

public final class GetSecureLinkKeys: GetSecureLinkKeysUseCase {
    private let passKeyManager: any PassKeyManagerProtocol
    private let userManager: any UserManagerProtocol

    public init(passKeyManager: any PassKeyManagerProtocol,
                userManager: any UserManagerProtocol) {
        self.passKeyManager = passKeyManager
        self.userManager = userManager
    }

    /// Generates link and encoded item keys
    /// - Parameter item: Item to be publicly shared
    /// - Returns: A tuple with the link and item encoded keys
    public func execute(item: ItemContent,
                        share: Share,
                        encryptedWithItemKey: Bool) async throws -> SecureLinkKeys {
        let userId = try await userManager.getActiveUserId()

        let itemKeyInfo: any ShareKeyProtocol = if share.shareType == .vault {
            try await passKeyManager.getLatestItemKey(userId: userId,
                                                      shareId: item.shareId,
                                                      itemId: item.itemId)
        } else {
            try await passKeyManager.getLatestShareKey(userId: userId, shareId: item.shareId)
        }

        let test = true
//        let shareKeyInfo: any ShareKeyProtocol = if test /* encryptedWithItemKey */ {
//            try await passKeyManager.getLatestItemKey(userId: userId,
//                                                      shareId: item.shareId,
//                                                      itemId: item.itemId)
//        } else {
//            try await passKeyManager.getLatestShareKey(userId: userId, shareId: item.shareId)
//        }

        let shareKeyInfo = try await passKeyManager.getLatestShareKey(userId: userId, shareId: item.shareId)

        let linkKey = try Data.random()

        let encryptedItemKey = try AES.GCM.seal(itemKeyInfo.keyData,
                                                key: linkKey,
                                                associatedData: .itemKey)

        let encryptedLinkKey = try AES.GCM.seal(linkKey,
                                                key: /* encryptedWithItemKey */ test ? itemKeyInfo
                                                    .keyData : shareKeyInfo.keyData,
                                                associatedData: .linkKey)

        return SecureLinkKeys(linkKey: linkKey.base64URLSafeEncodedString(),
                              itemKeyEncoded: encryptedItemKey.base64EncodedString(),
                              linkKeyEncoded: encryptedLinkKey.base64EncodedString(),
                              shareKeyRotation: shareKeyInfo.keyRotation)
    }
}
