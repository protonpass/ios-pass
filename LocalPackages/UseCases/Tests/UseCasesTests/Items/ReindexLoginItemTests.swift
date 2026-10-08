//
// ReindexLoginItemTests.swift
// Proton Pass - Created on 08/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import EntitiesMocks
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
struct ReindexLoginItemTests {
    @Test func `removes the one-time code identities of a website switched to never`() async throws {
        let manager = CredentialManagerSpy()
        let sut = ReindexLoginItem(manager: manager,
                                   matchUrls: MatchUrls(getRootDomain: GetRootDomain()),
                                   mapServiceIdentifierToUrl: MapASCredentialServiceIdentifierToURL())
        let login = LogInItemData.mock(autofillUrls: [
            .init(url: "https://never.example", mode: .never),
            .init(url: "https://kept.example", mode: .default)
        ])
        let item = ItemContent(shareId: "share", itemUuid: "uuid", userId: "user",
                               item: .random(itemId: "item"),
                               name: "Login", note: "", contentData: .login(login), customFields: [],
                               simpleLoginNote: nil)

        try await sut(item: item, identifiers: [], lastUseTime: .now)

        #expect(Set(manager.removed.compactMap(\.oneTimeCodeUrl)) == [
            "https://never.example",
            "https://kept.example"
        ])
        #expect(Set(manager.removed.compactMap(\.passwordUrl)) == [
            "https://never.example",
            "https://kept.example"
        ])
        #expect(manager.inserted.compactMap(\.oneTimeCodeUrl) == ["https://kept.example"])
        #expect(manager.inserted.compactMap(\.passwordUrl) == ["https://kept.example"])
    }
}

/// `@unchecked Sendable`: only the use case under test calls it, one awaited call at a time.
private final class CredentialManagerSpy: @unchecked Sendable, CredentialManagerProtocol {
    private(set) var removed = [CredentialIdentity]()
    private(set) var inserted = [CredentialIdentity]()

    var isAutoFillEnabled: Bool {
        true
    }

    func remove(credentials: [CredentialIdentity]) async throws {
        removed += credentials
    }

    func insert(credentials: [CredentialIdentity]) async throws {
        inserted += credentials
    }

    func removeAllCredentials() async throws {}

    func enableAutoFill() async -> Bool {
        true
    }
}

private extension CredentialIdentity {
    var passwordUrl: String? {
        if case let .password(identity) = self {
            identity.url
        } else {
            nil
        }
    }

    var oneTimeCodeUrl: String? {
        if case let .oneTimeCode(identity) = self {
            identity.url
        } else {
            nil
        }
    }
}
