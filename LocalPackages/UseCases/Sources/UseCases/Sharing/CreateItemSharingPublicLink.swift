//
//
// CreateItemSharingPublicLink.swift
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

public protocol CreateItemSharingPublicLinkUseCase: Sendable {
    func execute(item: ItemContent, expirationTime: Int, maxReadCount: Int?) async throws -> SharedPublicLink
}

public extension CreateItemSharingPublicLinkUseCase {
    func callAsFunction(item: ItemContent, expirationTime: Int,
                        maxReadCount: Int? = nil) async throws -> SharedPublicLink {
        try await execute(item: item, expirationTime: expirationTime, maxReadCount: maxReadCount)
    }
}

public final class CreateItemSharingPublicLink: CreateItemSharingPublicLinkUseCase {
    private let getPublicLinkKeys: any GetPublicLinkKeysUseCase
    private let repository: any PublicLinkRepositoryProtocol

    public init(repository: any PublicLinkRepositoryProtocol,
                getPublicLinkKeys: any GetPublicLinkKeysUseCase) {
        self.repository = repository
        self.getPublicLinkKeys = getPublicLinkKeys
    }

    public func execute(item: ItemContent, expirationTime: Int,
                        maxReadCount: Int?) async throws -> SharedPublicLink {
        let keyResults = try await getPublicLinkKeys(item: item)
        let configuration = PublicLinkCreationConfiguration(shareId: item.shareId,
                                                            itemId: item.itemId,
                                                            revision: Int(item.item.revision),
                                                            expirationTime: expirationTime,
                                                            encryptedItemKey: keyResults.encryptedItemKey,
                                                            maxReadCount: maxReadCount)
        let link = try await repository.createPublicLink(configuration: configuration)
        return link.update(with: keyResults.linkKey)
    }
}
