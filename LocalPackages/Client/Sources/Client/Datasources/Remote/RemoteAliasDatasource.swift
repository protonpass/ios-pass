//
// RemoteAliasDatasource.swift
// Proton Pass - Created on 14/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import Entities
import Foundation

public protocol RemoteAliasDatasourceProtocol: Sendable {
    func getAliasOptions(userId: String, shareId: String) async throws -> AliasOptions
    func getAliasDetails(userId: String, shareId: String, itemId: String) async throws -> Alias
    func changeMailboxes(userId: String, shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias

    // MARK: - SimpleLogin alias Sync

    func getAliasSyncStatus(userId: String) async throws -> AliasSyncStatus
    func enableSlAliasSync(userId: String, defaultShareID: String?) async throws
    func getPendingAliasesToSync(userId: String,
                                 since: String?,
                                 pageSize: Int) async throws -> PaginatedPendingAliases
    func getAliasSettings(userId: String) async throws -> AliasSettings
    func updateAliasDefaultDomain(userId: String, request: UpdateAliasDomainRequest) async throws -> AliasSettings
    func updateAliasDefaultMailbox(userId: String, request: UpdateAliasMailboxRequest) async throws -> AliasSettings
    func getAllAliasDomains(userId: String) async throws -> [Domain]
    func getAllAliasMailboxes(userId: String) async throws -> [MailboxSettings]
}

public final class RemoteAliasDatasource: RemoteDatasource, RemoteAliasDatasourceProtocol {}

public extension RemoteAliasDatasource {
    func getAliasOptions(userId: String, shareId: String) async throws -> AliasOptions {
        let endpoint = GetAliasOptionsEndpoint(shareId: shareId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.options
    }

    func getAliasDetails(userId: String, shareId: String, itemId: String) async throws -> Alias {
        let endpoint = GetAliasDetailsEndpoint(shareId: shareId, itemId: itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.alias
    }

    func changeMailboxes(userId: String,
                         shareId: String,
                         itemId: String,
                         mailboxIDs: [Int]) async throws -> Alias {
        let endpoint = ChangeMailboxesEndpoint(shareId: shareId,
                                               itemId: itemId,
                                               mailboxIDs: mailboxIDs)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.alias
    }
}

public extension RemoteAliasDatasource {
    func getAliasSyncStatus(userId: String) async throws -> AliasSyncStatus {
        let endpoint = GetAliasSyncStatusEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.syncStatus
    }

    func enableSlAliasSync(userId: String, defaultShareID: String?) async throws {
        let endpoint = EnableSLAliasSyncEndpoint(request: EnableSLAliasSyncRequest(defaultShareID: defaultShareID))
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func getPendingAliasesToSync(userId: String,
                                 since: String?,
                                 pageSize: Int) async throws -> PaginatedPendingAliases {
        let endpoint = GetAliasesPendingToSyncEndpoint(since: since, pageSize: pageSize)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.pendingAliases
    }

    func getAliasSettings(userId: String) async throws -> AliasSettings {
        let endpoint = GetAliasSettingsEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.settings
    }

    func updateAliasDefaultDomain(userId: String, request: UpdateAliasDomainRequest) async throws -> AliasSettings {
        let endpoint = UpdateAliasDomainEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.settings
    }
    
    func updateAliasDefaultMailbox(userId: String, request: UpdateAliasMailboxRequest) async throws -> AliasSettings {
        let endpoint = UpdateAliasMailboxEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.settings
    }

    func getAllAliasDomains(userId: String) async throws -> [Domain] {
        let endpoint = GetAllAliasDomainsEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.domains
    }
    
    func getAllAliasMailboxes(userId: String) async throws -> [MailboxSettings] {
        let endpoint = GetAllMailboxesEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.mailboxes
    }
}
