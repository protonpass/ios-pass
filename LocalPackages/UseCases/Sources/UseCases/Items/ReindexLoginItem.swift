//
// ReindexLoginItem.swift
// Proton Pass - Created on 10/11/2023.
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
//

#if canImport(AuthenticationServices)
import AuthenticationServices
import Client
import Core
import Entities
import Foundation

/// Put on top the suggested login items for an `ASCredentialServiceIdentifier`
/// As we don't update the `lastUseTime` of the item locally right after autofilling
/// we need this use case to explicitly give a `lastUseTime` to a login item
public protocol ReindexLoginItemUseCase: Sendable {
    func execute(item: ItemContent,
                 identifiers: [ASCredentialServiceIdentifier],
                 lastUseTime: Date) async throws
}

public extension ReindexLoginItemUseCase {
    func callAsFunction(item: ItemContent,
                        identifiers: [ASCredentialServiceIdentifier],
                        lastUseTime: Date) async throws {
        try await execute(item: item, identifiers: identifiers, lastUseTime: lastUseTime)
    }
}

public final class ReindexLoginItem: ReindexLoginItemUseCase {
    private let manager: CredentialManagerProtocol
    private let mapServiceIdentifierToUrl: MapASCredentialServiceIdentifierToURLUseCase

    public init(manager: CredentialManagerProtocol,
                mapServiceIdentifierToUrl: MapASCredentialServiceIdentifierToURLUseCase) {
        self.manager = manager
        self.mapServiceIdentifierToUrl = mapServiceIdentifierToUrl
    }

    public func execute(item: ItemContent,
                        identifiers: [ASCredentialServiceIdentifier],
                        lastUseTime: Date) async throws {
        guard case let .login(data) = item.contentData else {
            throw PassError.credentialProvider(.notLogInItem)
        }

        // First we remove existing indexed credentials
        let oldCredentials = data.urls.map { AutoFillCredential(shareId: item.shareId,
                                                                itemId: item.item.itemID,
                                                                username: data.username,
                                                                url: $0,
                                                                lastUseTime: item.item.lastUseTime ?? 0) }
        try await manager.remove(credentials: oldCredentials)

        // Then we insert updated credentials
        let givenUrls = identifiers.compactMap(mapServiceIdentifierToUrl.callAsFunction)
        let parser = try DomainParser()
        let credentials = data.urls.map { url -> AutoFillCredential in
            let isMatched = givenUrls.map { givenUrl -> Bool in
                guard let url = URL(string: url) else {
                    return false
                }
                let result = URLUtils.Matcher.compare(url, givenUrl, domainParser: parser)
                return switch result {
                case .matched:
                    true
                case .notMatched:
                    false
                }
            }
            .contains(true)

            let lastUseTime = if isMatched {
                Int64(lastUseTime.timeIntervalSince1970)
            } else {
                item.item.lastUseTime ?? 0
            }

            return .init(shareId: item.shareId,
                         itemId: item.itemId,
                         username: data.username,
                         url: url,
                         lastUseTime: lastUseTime)
        }
        try await manager.insert(credentials: credentials)
    }
}
#endif
