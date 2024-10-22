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
    func updateSlAliasName(userId: String,
                           shareId: String,
                           itemId: String,
                           name: String?) async throws
    func updateSlAliasNote(userId: String,
                           shareId: String,
                           itemId: String,
                           note: String?) async throws
    func getPendingAliasesToSync(userId: String,
                                 since: String?,
                                 pageSize: Int) async throws -> PaginatedPendingAliases
    func getAliasSettings(userId: String) async throws -> AliasSettings
    func updateAliasDefaultDomain(userId: String, request: UpdateAliasDomainRequest) async throws -> AliasSettings
    func updateAliasDefaultMailbox(userId: String, request: UpdateAliasMailboxRequest) async throws
        -> AliasSettings
    func getAllAliasDomains(userId: String) async throws -> [Domain]
    func getAllAliasMailboxes(userId: String) async throws -> [Mailbox]
    func createMailbox(userId: String, request: CreateMailboxRequest) async throws -> Mailbox
    func deleteMailbox(userId: String,
                       mailboxID: Int,
                       transferMailboxId: Int?) async throws
    func verifyMailbox(userId: String, mailboxID: Int, request: VerifyMailboxRequest) async throws -> Mailbox
    func resendMailboxVerificationEmail(userId: String, mailboxID: Int) async throws -> Mailbox

    func getAliasContacts(userId: String,
                          shareId: String,
                          itemId: String,
                          lastContactId: String?) async throws -> PaginatedAliasContacts
    func createAliasContact(userId: String,
                            shareId: String,
                            itemId: String,
                            request: CreateAContactRequest) async throws -> AliasContactLite
    func getAliasContactInfos(userId: String,
                              shareId: String,
                              itemId: String,
                              contactId: String) async throws -> AliasContact
    func updateAliasContact(userId: String,
                            shareId: String,
                            itemId: String,
                            contactId: String,
                            request: UpdateContactRequest) async throws -> AliasContactLite
    func deleteContact(userId: String,
                       shareId: String,
                       itemId: String,
                       contactId: String) async throws
}

public final class RemoteAliasDatasource: RemoteDatasource, RemoteAliasDatasourceProtocol, @unchecked Sendable {}

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

    func updateSlAliasName(userId: String,
                           shareId: String,
                           itemId: String,
                           name: String?) async throws {
        let endpoint = UpdateAliasSlNameEndpoint(shareId: shareId, itemId: itemId, name: name)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func updateSlAliasNote(userId: String,
                           shareId: String,
                           itemId: String,
                           note: String?) async throws {
        let endpoint = UpdateAliasSlNoteEndpoint(shareId: shareId, itemId: itemId, note: note)
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

    func updateAliasDefaultDomain(userId: String,
                                  request: UpdateAliasDomainRequest) async throws -> AliasSettings {
        let endpoint = UpdateAliasDomainEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.settings
    }

    func updateAliasDefaultMailbox(userId: String,
                                   request: UpdateAliasMailboxRequest) async throws -> AliasSettings {
        let endpoint = UpdateAliasMailboxEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.settings
    }

    func getAllAliasDomains(userId: String) async throws -> [Domain] {
        let endpoint = GetAllAliasDomainsEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.domains
    }

    func getAllAliasMailboxes(userId: String) async throws -> [Mailbox] {
        let endpoint = GetAllMailboxesEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.mailboxes
    }

    func createMailbox(userId: String, request: CreateMailboxRequest) async throws -> Mailbox {
        let endpoint = CreateMailboxEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.mailbox
    }

    func deleteMailbox(userId: String, mailboxID: Int, transferMailboxId: Int?) async throws {
        let endpoint = DeleteMailboxEndpoint(mailboxID: "\(mailboxID)",
                                             transferMailboxId: transferMailboxId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func verifyMailbox(userId: String, mailboxID: Int, request: VerifyMailboxRequest) async throws -> Mailbox {
        let endpoint = VerifyMailboxEndpoint(mailboxID: "\(mailboxID)", request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.mailbox
    }

    func resendMailboxVerificationEmail(userId: String, mailboxID: Int) async throws -> Mailbox {
        let endpoint = ResendMailboxVerificationEmailEndpoint(mailboxID: "\(mailboxID)")
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.mailbox
    }
}

// MARK: - Contacts

public extension RemoteAliasDatasource {
    func getAliasContacts(userId: String,
                          shareId: String,
                          itemId: String,
                          lastContactId: String?) async throws -> PaginatedAliasContacts {
        let query = GetAliasContactsQuery(lastContactId: lastContactId)
        let endpoint = GetAliasContactsEndpoint(shareId: shareId, itemId: itemId, query: query)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response
    }

    func createAliasContact(userId: String,
                            shareId: String,
                            itemId: String,
                            request: CreateAContactRequest) async throws -> AliasContactLite {
        let endpoint = CreateAContactEndpoint(shareId: shareId, itemId: itemId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.contact
    }

    func getAliasContactInfos(userId: String,
                              shareId: String,
                              itemId: String,
                              contactId: String) async throws -> AliasContact {
        let endpoint = GetContactInfoEndpoint(shareId: shareId, itemId: itemId, contactId: contactId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.contact
    }

    func updateAliasContact(userId: String,
                            shareId: String,
                            itemId: String,
                            contactId: String,
                            request: UpdateContactRequest) async throws -> AliasContactLite {
        let endpoint = UpdateContactEndpoint(shareId: shareId,
                                             itemId: itemId,
                                             contactId: contactId,
                                             request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.contact
    }

    func deleteContact(userId: String,
                       shareId: String,
                       itemId: String,
                       contactId: String) async throws {
        let endpoint = DeleteContactEndpoint(shareId: shareId,
                                             itemId: itemId,
                                             contactId: contactId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }
}
