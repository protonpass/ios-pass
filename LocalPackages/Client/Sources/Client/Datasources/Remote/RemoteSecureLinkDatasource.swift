//
// RemoteSecureLinkDatasource.swift
// Proton Pass - Created on 15/05/2024.
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

// swiftlint:disable:next todo
// TODO: Remove later on
// periphery:ignore:all

import Entities

public protocol RemoteSecureLinkDatasourceProtocol: Sendable {
    func createLink(userId: String, configuration: SecureLinkCreationConfiguration) async throws -> NewSecureLink
    func deleteLink(userId: String, linkId: String) async throws
    func getAllLinks(userId: String) async throws -> [SecureLink]
    func getLinkContent(userId: String, linkToken: String) async throws -> SecureLinkContent
    func deleteAllInactiveLinks(userId: String) async throws
}

public final class RemoteSecureLinkDatasource: RemoteDatasource, RemoteSecureLinkDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteSecureLinkDatasource {
    func createLink(userId: String, configuration: SecureLinkCreationConfiguration) async throws -> NewSecureLink {
        let request = CreateSecureLinkRequest(revision: configuration.revision,
                                              expirationTime: configuration.expirationTime,
                                              maxReadCount: configuration.maxReadCount,
                                              encryptedItemKey: configuration.encryptedItemKey,
                                              encryptedLinkKey: configuration.encryptedLinkKey,
                                              linkKeyShareKeyRotation: configuration.linkKeyShareKeyRotation)
        let endpoint = CreatePublicLinkEndpoint(shareId: configuration.shareId,
                                                itemId: configuration.itemId,
                                                request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.publicLink
    }

    func deleteLink(userId: String, linkId: String) async throws {
        let endpoint = DeleteSecureLinkEndpoint(linkId: linkId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func getAllLinks(userId: String) async throws -> [SecureLink] {
        let endpoint = GetAllPublicLinksForUserEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.publicLinks
    }

    func getLinkContent(userId: String, linkToken: String) async throws -> SecureLinkContent {
        let endpoint = GetSecureLinkContentEndpoint(linkToken: linkToken)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.publicLinkContent
    }

    func deleteAllInactiveLinks(userId: String) async throws {
        let endpoint = DeleteAllInactiveLinksEndpoint()
        _ = try await exec(userId: userId, endpoint: endpoint)
    }
}
