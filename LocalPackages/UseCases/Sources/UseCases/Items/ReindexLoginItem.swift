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

import AuthenticationServices
import Client
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
    private let manager: any CredentialManagerProtocol
    private let matchUrls: any MatchUrlsUseCase
    private let mapServiceIdentifierToUrl: any MapASCredentialServiceIdentifierToURLUseCase

    public init(manager: any CredentialManagerProtocol,
                matchUrls: any MatchUrlsUseCase,
                mapServiceIdentifierToUrl: any MapASCredentialServiceIdentifierToURLUseCase) {
        self.manager = manager
        self.matchUrls = matchUrls
        self.mapServiceIdentifierToUrl = mapServiceIdentifierToUrl
    }

    public func execute(item: ItemContent,
                        identifiers: [ASCredentialServiceIdentifier],
                        lastUseTime: Date) async throws {
        guard case let .login(data) = item.contentData else {
            throw PassError.credentialProvider(.notLogInItem)
        }

        // First we remove existing indexed credentials
        let oldPasswords = data.urls.map {
            CredentialIdentity.password(.init(shareId: item.shareId,
                                              itemId: item.item.itemID,
                                              username: data.authIdentifier,
                                              url: $0,
                                              lastUseTime: item.item.lastUseTime ?? 0))
        }

        try await manager.remove(credentials: oldPasswords)

        // Then we insert updated credentials
        let givenUrls = identifiers.compactMap(mapServiceIdentifierToUrl.callAsFunction)

        var passwords = [CredentialIdentity]()
        if !data.authIdentifier.isEmpty, !data.password.isEmpty {
            passwords = data.urls.map { url -> CredentialIdentity in
                let isMatched = givenUrls.map { givenUrl -> Bool in
                    guard let url = URL(string: url),
                          let result = try? matchUrls(url, with: givenUrl) else {
                        return false
                    }
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

                return CredentialIdentity.password(.init(shareId: item.shareId,
                                                         itemId: item.itemId,
                                                         username: data.authIdentifier,
                                                         url: url,
                                                         lastUseTime: lastUseTime))
            }
        }

        var oneTimeCodes = [CredentialIdentity]()
        if !data.authIdentifier.isEmpty, !data.totpUri.isEmpty {
            oneTimeCodes = data.urls.map {
                CredentialIdentity.oneTimeCode(.init(shareId: item.shareId,
                                                     itemId: item.itemId,
                                                     username: data.authIdentifier,
                                                     url: $0))
            }
        }

        let passkeys = data.passkeys.map {
            CredentialIdentity.passkey(.init(shareId: item.shareId,
                                             itemId: item.itemId,
                                             relyingPartyIdentifier: $0.rpID,
                                             userName: $0.userName,
                                             userHandle: $0.userHandle,
                                             credentialId: $0.credentialID))
        }

        try await manager.insert(credentials: passwords + oneTimeCodes + passkeys)
    }
}
