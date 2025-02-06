//
//
// CreateSecureLink.swift
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
import Entities
import Foundation

public protocol CreateSecureLinkUseCase: Sendable {
    func execute(item: ItemContent,
                 share: Share,
                 expirationTime: Int,
                 maxReadCount: Int?) async throws -> NewSecureLink
}

public extension CreateSecureLinkUseCase {
    func callAsFunction(item: ItemContent,
                        share: Share,
                        expirationTime: Int,
                        maxReadCount: Int? = nil) async throws -> NewSecureLink {
        try await execute(item: item, share: share, expirationTime: expirationTime, maxReadCount: maxReadCount)
    }
}

public final class CreateSecureLink: CreateSecureLinkUseCase {
    private let getSecureLinkKeys: any GetSecureLinkKeysUseCase
    private let datasource: any RemoteSecureLinkDatasourceProtocol
    private let manager: any SecureLinkManagerProtocol
    private let userManager: any UserManagerProtocol
    private let getFeatureFlagStatus: any GetFeatureFlagStatusUseCase

    public init(datasource: any RemoteSecureLinkDatasourceProtocol,
                getSecureLinkKeys: any GetSecureLinkKeysUseCase,
                userManager: any UserManagerProtocol,
                manager: any SecureLinkManagerProtocol,
                getFeatureFlagStatus: any GetFeatureFlagStatusUseCase) {
        self.datasource = datasource
        self.getSecureLinkKeys = getSecureLinkKeys
        self.userManager = userManager
        self.manager = manager
        self.getFeatureFlagStatus = getFeatureFlagStatus
    }

    public func execute(item: ItemContent,
                        share: Share,
                        expirationTime: Int,
                        maxReadCount: Int?) async throws -> NewSecureLink {
        let encryptedWithItemKey = getFeatureFlagStatus(for: FeatureFlagType.passSecureLinkCryptoChangeV1)
        let keys = try await getSecureLinkKeys(item: item,
                                               share: share,
                                               encryptedWithItemKey: encryptedWithItemKey)
        let userId = try await userManager.getActiveUserId()
        let configuration = SecureLinkCreationConfiguration(shareId: item.shareId,
                                                            itemId: item.itemId,
                                                            revision: Int(item.item.revision),
                                                            expirationTime: expirationTime,
                                                            encryptedItemKey: keys.itemKeyEncoded,
                                                            maxReadCount: maxReadCount,
                                                            encryptedLinkKey: keys.linkKeyEncoded,
                                                            linkKeyShareKeyRotation: keys.shareKeyRotation,
                                                            linkKeyEncryptedWithItemKey: encryptedWithItemKey)
        let link = try await datasource.createLink(userId: userId, configuration: configuration)
        try await manager.updateSecureLinks()
        return link.update(with: keys.linkKey)
    }
}
