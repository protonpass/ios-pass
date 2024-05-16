//
//
// GetPublicLinkKeys.swift
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

// swiftlint:disable:next todo
// TODO: Remove later on
// periphery:ignore:all

import Client
import CryptoKit
import Entities
import Foundation

protocol GetPublicLinkKeysUseCase: Sendable {
    func execute(item: ItemContent) async throws -> (linkKey: String, encryptedItemKey: String)
}

extension GetPublicLinkKeysUseCase {
    func callAsFunction(item: ItemContent) async throws -> (linkKey: String, encryptedItemKey: String) {
        try await execute(item: item)
    }
}

final class GetPublicLinkKeys: GetPublicLinkKeysUseCase {
    private let passKeyManager: any PassKeyManagerProtocol

    init(passKeyManager: any PassKeyManagerProtocol) {
        self.passKeyManager = passKeyManager
    }

    /// Generates link and encoded item keys
    /// - Parameter item: Item to be publicly shared
    /// - Returns: A tuple with the link and item encoded keys
    func execute(item: ItemContent) async throws -> (linkKey: String, encryptedItemKey: String) {
        let itemKeyInfo = try await passKeyManager.getLatestItemKey(shareId: item.shareId, itemId: item.itemId)
        let linkKey = try Data.random()

        let encryptedItemKey = try AES.GCM.seal(itemKeyInfo.keyData,
                                                key: linkKey,
                                                associatedData: .itemKey)

        guard let itemKeyEncoded = encryptedItemKey.combined?.base64EncodedString() else {
            throw PassError.crypto(.failedToBase64Encode)
        }

        return (linkKey.base64EncodedString(), itemKeyEncoded)
    }
}
