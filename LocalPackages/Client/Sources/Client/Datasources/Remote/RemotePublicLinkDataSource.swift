//
// RemotePublicLinkDataSource.swift
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

// sourcery: AutoMockable
public protocol RemotePublicLinkDataSourceProtocol: Sendable {
    func createPublicLink(configuration: PublicLinkCreationConfiguration) async throws -> SharedPublicLink
    func deletePublicLink(publicLinkId: String) async throws
    func getAllPublicLinksForUser() async throws -> [PublicLink]
    func getPublicLinkContent(publicLinkToken: String) async throws -> PublicLinkContent
}

public final class RemotePublicLinkDataSource: RemoteDatasource, RemotePublicLinkDataSourceProtocol {}

public extension RemotePublicLinkDataSource {
    func createPublicLink(configuration: PublicLinkCreationConfiguration) async throws -> SharedPublicLink {
        let request = CreatePublicLinkRequest(revision: configuration.revision,
                                              expirationTime: configuration.expirationTime,
                                              maxReadCount: configuration.maxReadCount,
                                              encryptedItemKey: configuration.encryptedItemKey)
        let endpoint = CreatePublicLinkEndpoint(shareId: configuration.shareId,
                                                itemId: configuration.itemId,
                                                request: request)
        let response = try await exec(endpoint: endpoint)
        return response.publicLink
    }

    func deletePublicLink(publicLinkId: String) async throws {
        let endpoint = DeletePublicLinkEndpoint(publicLinkId: publicLinkId)
        _ = try await exec(endpoint: endpoint)
    }

    func getAllPublicLinksForUser() async throws -> [PublicLink] {
        let endpoint = GetAllPublicLinksForUserEndpoint()
        let response = try await exec(endpoint: endpoint)
        return response.publicLinks.publicLinks
    }

    func getPublicLinkContent(publicLinkToken: String) async throws -> PublicLinkContent {
        let endpoint = GetPublicLinkContentEndpoint(publicLinkToken: publicLinkToken)
        let response = try await exec(endpoint: endpoint)
        return response.publicLinkContent
    }
}
