//
// AliasRepository.swift
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

@preconcurrency import Combine
import Core
import Entities

public protocol AliasRepositoryProtocol: Sendable {
    var mailboxUpdated: PassthroughSubject<Void, Never> { get }
    var contactsUpdated: PassthroughSubject<Void, Never> { get }

    func getAliasOptions(shareId: String) async throws -> AliasOptions
    func getAliasDetails(shareId: String, itemId: String) async throws -> Alias
    @discardableResult
    func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias

    // MARK: - Simple login alias Sync

    func getAliasSyncStatus(userId: String) async throws -> AliasSyncStatus
    func enableSlAliasSync(userId: String, defaultShareID: String?) async throws
    func updateSlAliasName(userId: String, shareId: String, itemId: String, name: String?) async throws
    func getPendingAliasesToSync(userId: String,
                                 since: String?,
                                 pageSize: Int) async throws -> PaginatedPendingAliases

    func getAliasSettings(userId: String) async throws -> AliasSettings
    @discardableResult
    func updateAliasDefaultDomain(userId: String, request: UpdateAliasDomainRequest) async throws -> AliasSettings
    @discardableResult
    func updateAliasDefaultMailbox(userId: String, request: UpdateAliasMailboxRequest) async throws
        -> AliasSettings
    func getAllAliasDomains(userId: String) async throws -> [Domain]
    func getAllAliasMailboxes(userId: String) async throws -> [Mailbox]

    func createMailbox(userId: String, email: String) async throws -> Mailbox
    func deleteMailbox(userId: String, mailboxID: Int, transferMailboxID: Int?) async throws
    func verifyMailbox(userId: String, mailboxID: Int, code: String) async throws -> Mailbox
    func resendMailboxVerificationEmail(userId: String, mailboxID: Int) async throws -> Mailbox

    func getContacts(userId: String,
                     shareId: String,
                     itemId: String,
                     lastContactId: String?) async throws -> PaginatedAliasContacts
    func createContact(userId: String,
                       shareId: String,
                       itemId: String,
                       request: CreateAContactRequest) async throws -> AliasContact
    func getContactInfos(userId: String,
                         shareId: String,
                         itemId: String,
                         contactId: String) async throws -> AliasContact
    func updateContact(userId: String,
                       shareId: String,
                       itemId: String,
                       contactId: String,
                       blocked: Bool) async throws -> LightAliasContact

    func deleteContact(userId: String,
                       shareId: String,
                       itemId: String,
                       contactId: String) async throws
}

public extension AliasRepositoryProtocol {
    func getPendingAliasesToSync(userId: String,
                                 since: String?) async throws -> PaginatedPendingAliases {
        try await getPendingAliasesToSync(userId: userId, since: since, pageSize: Constants.Utils.defaultPageSize)
    }
}

public actor AliasRepository: AliasRepositoryProtocol {
    private let remoteDatasource: any RemoteAliasDatasourceProtocol
    private let userManager: any UserManagerProtocol

    public nonisolated let mailboxUpdated: PassthroughSubject<Void, Never> = .init()
    public nonisolated let contactsUpdated: PassthroughSubject<Void, Never> = .init()

    public init(remoteDatasource: any RemoteAliasDatasourceProtocol,
                userManager: any UserManagerProtocol) {
        self.remoteDatasource = remoteDatasource
        self.userManager = userManager
    }
}

public extension AliasRepository {
    func getAliasOptions(shareId: String) async throws -> AliasOptions {
        let userId = try await userManager.getActiveUserId()
        return try await remoteDatasource.getAliasOptions(userId: userId, shareId: shareId)
    }

    func getAliasDetails(shareId: String, itemId: String) async throws -> Alias {
        let userId = try await userManager.getActiveUserId()
        return try await remoteDatasource.getAliasDetails(userId: userId, shareId: shareId, itemId: itemId)
    }

    func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias {
        let userId = try await userManager.getActiveUserId()
        return try await remoteDatasource.changeMailboxes(userId: userId,
                                                          shareId: shareId,
                                                          itemId: itemId,
                                                          mailboxIDs: mailboxIDs)
    }
}

// MARK: - Simple login alias Sync

public extension AliasRepository {
    func getAliasSyncStatus(userId: String) async throws -> AliasSyncStatus {
        try await remoteDatasource.getAliasSyncStatus(userId: userId)
    }

    func enableSlAliasSync(userId: String, defaultShareID: String?) async throws {
        try await remoteDatasource.enableSlAliasSync(userId: userId, defaultShareID: defaultShareID)
    }

    func updateSlAliasName(userId: String, shareId: String, itemId: String, name: String?) async throws {
        let request = UpdateAliasSlNameRequest(name: name)
        try await remoteDatasource.updateSlAliasName(userId: userId,
                                                     shareId: shareId,
                                                     itemId: itemId,
                                                     request: request)
    }

    func getPendingAliasesToSync(userId: String,
                                 since: String?,
                                 pageSize: Int = Constants.Utils
                                     .defaultPageSize) async throws -> PaginatedPendingAliases {
        try await remoteDatasource.getPendingAliasesToSync(userId: userId, since: since, pageSize: pageSize)
    }

    func getAliasSettings(userId: String) async throws -> AliasSettings {
        try await remoteDatasource.getAliasSettings(userId: userId)
    }

    func updateAliasDefaultDomain(userId: String,
                                  request: UpdateAliasDomainRequest) async throws -> AliasSettings {
        try await remoteDatasource.updateAliasDefaultDomain(userId: userId, request: request)
    }

    func updateAliasDefaultMailbox(userId: String,
                                   request: UpdateAliasMailboxRequest) async throws -> AliasSettings {
        try await remoteDatasource.updateAliasDefaultMailbox(userId: userId, request: request)
    }

    func getAllAliasDomains(userId: String) async throws -> [Domain] {
        try await remoteDatasource.getAllAliasDomains(userId: userId)
    }
}

// MARK: - Mailboxes

public extension AliasRepository {
    func getAllAliasMailboxes(userId: String) async throws -> [Mailbox] {
        try await remoteDatasource.getAllAliasMailboxes(userId: userId)
    }

    func createMailbox(userId: String, email: String) async throws -> Mailbox {
        let request = CreateMailboxRequest(email: email)
        let mailbox = try await remoteDatasource.createMailbox(userId: userId, request: request)
        mailboxUpdated.send(())
        return mailbox
    }

    func deleteMailbox(userId: String, mailboxID: Int, transferMailboxID: Int?) async throws {
        let id: String? = if let transferMailboxID {
            "\(transferMailboxID)"
        } else {
            nil
        }

        let request = DeleteMailboxRequest(transferMailboxID: id)
        try await remoteDatasource.deleteMailbox(userId: userId, mailboxID: mailboxID, request: request)
        mailboxUpdated.send(())
    }

    func verifyMailbox(userId: String, mailboxID: Int, code: String) async throws -> Mailbox {
        let request = VerifyMailboxRequest(code: code)
        let mailbox = try await remoteDatasource.verifyMailbox(userId: userId,
                                                               mailboxID: mailboxID,
                                                               request: request)
        mailboxUpdated.send(())
        return mailbox
    }

    func resendMailboxVerificationEmail(userId: String, mailboxID: Int) async throws -> Mailbox {
        try await remoteDatasource.resendMailboxVerificationEmail(userId: userId, mailboxID: mailboxID)
    }
}

// MARK: - Contacts

public extension AliasRepository {
    func getContacts(userId: String,
                     shareId: String,
                     itemId: String,
                     lastContactId: String?) async throws -> PaginatedAliasContacts {
        try await remoteDatasource.getAliasContacts(userId: userId,
                                                    shareId: shareId,
                                                    itemId: itemId,
                                                    lastContactId: lastContactId)
    }

    func createContact(userId: String,
                       shareId: String,
                       itemId: String,
                       request: CreateAContactRequest) async throws -> AliasContact {
        let contact = try await remoteDatasource.createAliasContact(userId: userId,
                                                                    shareId: shareId,
                                                                    itemId: itemId,
                                                                    request: request)
        contactsUpdated.send(())
        return contact
    }

    func getContactInfos(userId: String,
                         shareId: String,
                         itemId: String,
                         contactId: String) async throws -> AliasContact {
        try await remoteDatasource.getAliasContactInfos(userId: userId,
                                                        shareId: shareId,
                                                        itemId: itemId,
                                                        contactId: contactId)
    }

    func updateContact(userId: String,
                       shareId: String,
                       itemId: String,
                       contactId: String,
                       blocked: Bool) async throws -> LightAliasContact {
        let request = UpdateContactRequest(blocked: blocked)
        let contact = try await remoteDatasource.updateAliasContact(userId: userId,
                                                                    shareId: shareId,
                                                                    itemId: itemId,
                                                                    contactId: contactId,
                                                                    request: request)
        contactsUpdated.send(())
        return contact
    }

    func deleteContact(userId: String,
                       shareId: String,
                       itemId: String,
                       contactId: String) async throws {
        try await remoteDatasource.deleteContact(userId: userId,
                                                 shareId: shareId,
                                                 itemId: itemId,
                                                 contactId: contactId)
    }
}
