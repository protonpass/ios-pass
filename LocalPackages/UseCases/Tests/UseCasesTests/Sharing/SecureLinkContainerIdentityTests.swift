//
// SecureLinkContainerIdentityTests.swift
// Proton Pass - Created on 22/09/2026.
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

@testable import UseCases
import Client
import ClientMocks
import Core
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import Testing

struct SecureLinkContainerIdentityTests {
    @Test func `folder secure link creation and recreation round trip`() async throws {
        let keys = PassKeyManagerProtocolMock()
        let itemBytes = Data(repeating: 0x71, count: 32)
        let folderBytes = Data(repeating: 0x72, count: 32)
        let itemKey = DecryptedItemKey(containerId: "foldershare", itemId: "item", keyRotation: 1,
                                       keyData: itemBytes)
        keys.stubbedGetLatestItemKeyResult = itemKey
        keys.stubbedGetItemKeyResult = itemKey
        keys.stubbedGetContainerKeyResult = DecryptedFolderKey(shareId: "share", folderId: "folder",
                                                               keyRotation: 1, keyData: folderBytes)
        let item = ItemContent(shareId: "share", itemUuid: "uuid", userId: "account-B",
                               item: .random(itemId: "item", folderId: "folder", keyRotation: 1),
                               name: "unused", note: "", contentData: .note, customFields: [],
                               simpleLoginNote: nil)
        let share = Share.random(shareID: "share", targetType: 1)
        #expect(share.shareType == .vault)
        let created = try await GetSecureLinkKeys(passKeyManager: keys)(item: item, share: share)
        let linkData = try JSONSerialization.data(withJSONObject: [
            "linkID": "link", "expirationTime": 1, "shareID": "share", "itemID": "item",
            "linkURL": "https://example.test/link", "encryptedLinkKey": created.linkKeyEncoded,
            "linkKeyShareKeyRotation": 1, "active": true, "linkKeyEncryptedWithItemKey": true
        ])
        let decoder = JSONDecoder()
        let link = try decoder.decode(SecureLink.self, from: linkData)
        let recreated = try await RecreateSecureLink(passKeyManager: keys)(for: link, itemContent: item)
        #expect(recreated == "https://example.test/link#\(created.linkKey)")
        #expect(keys.invokedGetLatestItemKeyParameters?.userId == "account-B")
        #expect(keys.invokedGetLatestItemKeyParameters?.folderId == "folder")
        #expect(keys.invokedGetItemKeyParameters?.userId == "account-B")
        #expect(keys.invokedGetItemKeyParameters?.shareId == "share")
        #expect(keys.invokedGetItemKeyParameters?.folderId == "folder")
        #expect(keys.invokedGetContainerKeyParameters?.folderId == "folder")
    }
}

extension SecureLinkContainerIdentityTests {
    @Test func `creation request keeps the items account after key generation`() async throws {
        let datasource = LinkDatasource()
        let accountManager = UserManagerProtocolMock()
        accountManager.stubbedGetActiveUserDataResult = .random()
        let manager = SecureLinkManager(dataSource: datasource, userManager: accountManager)
        let item = ItemContent(shareId: "share", itemUuid: "uuid", userId: "account-B",
                               item: .random(itemId: "item", folderId: "folder", keyRotation: 1),
                               name: "unused", note: "", contentData: .note, customFields: [],
                               simpleLoginNote: nil)
        let create = CreateSecureLink(datasource: datasource, getSecureLinkKeys: LinkKeys(), manager: manager)
        _ = try await create(item: item, share: .random(shareID: "share", targetType: 1), expirationTime: 1)
        #expect(await datasource.createdForUser == "account-B")
    }
}

private struct LinkKeys: GetSecureLinkKeysUseCase {
    func execute(item: ItemContent, share: Share) async throws -> SecureLinkKeys {
        await Task.yield()
        return .init(linkKey: "link", itemKeyEncoded: "item", linkKeyEncoded: "wrapped", shareKeyRotation: 1)
    }
}

private actor LinkDatasource: RemoteSecureLinkDatasourceProtocol {
    private(set) var createdForUser: String?
    func createLink(userId: String, configuration: SecureLinkCreationConfiguration) async throws -> NewSecureLink {
        createdForUser = userId
        return try JSONDecoder().decode(NewSecureLink.self,
                                        from: Data(#"{"url":"https://example.test/link","publicLinkID":"link"}"#
                                            .utf8))
    }

    func getAllLinks(userId: String) async throws -> [SecureLink] {
        []
    }

    func deleteLink(userId: String, linkId: String) async throws {
        Issue.record("Unexpected deletion")
    }

    func deleteAllInactiveLinks(userId: String) async throws {
        Issue.record("Unexpected deletion")
    }

    func getLinkContent(userId: String, linkToken: String) async throws -> SecureLinkContent {
        throw CancellationError()
    }
}
