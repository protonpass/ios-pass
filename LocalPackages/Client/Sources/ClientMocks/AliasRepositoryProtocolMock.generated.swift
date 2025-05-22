// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Client
import Combine
import Core
import Entities

public final class AliasRepositoryProtocolMock: @unchecked Sendable, AliasRepositoryProtocol {

    public init() {}

    // MARK: - mailboxUpdated
    public var invokedMailboxUpdatedSetter = false
    public var invokedMailboxUpdatedSetterCount = 0
    public var invokedMailboxUpdated: PassthroughSubject<MailboxUpdateEvent, Never>?
    public var invokedMailboxUpdatedList = [PassthroughSubject<MailboxUpdateEvent, Never>?]()
    public var invokedMailboxUpdatedGetter = false
    public var invokedMailboxUpdatedGetterCount = 0
    public var stubbedMailboxUpdated: PassthroughSubject<MailboxUpdateEvent, Never>!
    public var mailboxUpdated: PassthroughSubject<MailboxUpdateEvent, Never> {
        set {
            invokedMailboxUpdatedSetter = true
            invokedMailboxUpdatedSetterCount += 1
            invokedMailboxUpdated = newValue
            invokedMailboxUpdatedList.append(newValue)
        } get {
            invokedMailboxUpdatedGetter = true
            invokedMailboxUpdatedGetterCount += 1
            return stubbedMailboxUpdated
        }
    }
    // MARK: - contactsUpdated
    public var invokedContactsUpdatedSetter = false
    public var invokedContactsUpdatedSetterCount = 0
    public var invokedContactsUpdated: PassthroughSubject<Void, Never>?
    public var invokedContactsUpdatedList = [PassthroughSubject<Void, Never>?]()
    public var invokedContactsUpdatedGetter = false
    public var invokedContactsUpdatedGetterCount = 0
    public var stubbedContactsUpdated: PassthroughSubject<Void, Never>!
    public var contactsUpdated: PassthroughSubject<Void, Never> {
        set {
            invokedContactsUpdatedSetter = true
            invokedContactsUpdatedSetterCount += 1
            invokedContactsUpdated = newValue
            invokedContactsUpdatedList.append(newValue)
        } get {
            invokedContactsUpdatedGetter = true
            invokedContactsUpdatedGetterCount += 1
            return stubbedContactsUpdated
        }
    }
    // MARK: - getAliasOptions
    public var getAliasOptionsUserIdShareIdThrowableError1: Error?
    public var closureGetAliasOptions: () -> () = {}
    public var invokedGetAliasOptionsfunction = false
    public var invokedGetAliasOptionsCount = 0
    public var invokedGetAliasOptionsParameters: (userId: String?, shareId: String)?
    public var invokedGetAliasOptionsParametersList = [(userId: String?, shareId: String)]()
    public var stubbedGetAliasOptionsResult: AliasOptions!

    public func getAliasOptions(userId: String?, shareId: String) async throws -> AliasOptions {
        invokedGetAliasOptionsfunction = true
        invokedGetAliasOptionsCount += 1
        invokedGetAliasOptionsParameters = (userId, shareId)
        invokedGetAliasOptionsParametersList.append((userId, shareId))
        if let error = getAliasOptionsUserIdShareIdThrowableError1 {
            throw error
        }
        closureGetAliasOptions()
        return stubbedGetAliasOptionsResult
    }
    // MARK: - getAliasDetails
    public var getAliasDetailsUserIdShareIdItemIdThrowableError2: Error?
    public var closureGetAliasDetails: () -> () = {}
    public var invokedGetAliasDetailsfunction = false
    public var invokedGetAliasDetailsCount = 0
    public var invokedGetAliasDetailsParameters: (userId: String?, shareId: String, itemId: String)?
    public var invokedGetAliasDetailsParametersList = [(userId: String?, shareId: String, itemId: String)]()
    public var stubbedGetAliasDetailsResult: Alias!

    public func getAliasDetails(userId: String?, shareId: String, itemId: String) async throws -> Alias {
        invokedGetAliasDetailsfunction = true
        invokedGetAliasDetailsCount += 1
        invokedGetAliasDetailsParameters = (userId, shareId, itemId)
        invokedGetAliasDetailsParametersList.append((userId, shareId, itemId))
        if let error = getAliasDetailsUserIdShareIdItemIdThrowableError2 {
            throw error
        }
        closureGetAliasDetails()
        return stubbedGetAliasDetailsResult
    }
    // MARK: - changeMailboxes
    public var changeMailboxesShareIdItemIdMailboxIDsThrowableError3: Error?
    public var closureChangeMailboxes: () -> () = {}
    public var invokedChangeMailboxesfunction = false
    public var invokedChangeMailboxesCount = 0
    public var invokedChangeMailboxesParameters: (shareId: String, itemId: String, mailboxIDs: [Int])?
    public var invokedChangeMailboxesParametersList = [(shareId: String, itemId: String, mailboxIDs: [Int])]()
    public var stubbedChangeMailboxesResult: Alias!

    public func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias {
        invokedChangeMailboxesfunction = true
        invokedChangeMailboxesCount += 1
        invokedChangeMailboxesParameters = (shareId, itemId, mailboxIDs)
        invokedChangeMailboxesParametersList.append((shareId, itemId, mailboxIDs))
        if let error = changeMailboxesShareIdItemIdMailboxIDsThrowableError3 {
            throw error
        }
        closureChangeMailboxes()
        return stubbedChangeMailboxesResult
    }
    // MARK: - changeMailboxEmail
    public var changeMailboxEmailUserIdMailboxIdNewMailboxEmailThrowableError4: Error?
    public var closureChangeMailboxEmail: () -> () = {}
    public var invokedChangeMailboxEmailfunction = false
    public var invokedChangeMailboxEmailCount = 0
    public var invokedChangeMailboxEmailParameters: (userId: String, mailboxId: Int, newMailboxEmail: String)?
    public var invokedChangeMailboxEmailParametersList = [(userId: String, mailboxId: Int, newMailboxEmail: String)]()
    public var stubbedChangeMailboxEmailResult: Mailbox!

    public func changeMailboxEmail(userId: String, mailboxId: Int, newMailboxEmail: String) async throws -> Mailbox {
        invokedChangeMailboxEmailfunction = true
        invokedChangeMailboxEmailCount += 1
        invokedChangeMailboxEmailParameters = (userId, mailboxId, newMailboxEmail)
        invokedChangeMailboxEmailParametersList.append((userId, mailboxId, newMailboxEmail))
        if let error = changeMailboxEmailUserIdMailboxIdNewMailboxEmailThrowableError4 {
            throw error
        }
        closureChangeMailboxEmail()
        return stubbedChangeMailboxEmailResult
    }
    // MARK: - cancelMailboxChange
    public var cancelMailboxChangeUserIdMailboxIdThrowableError5: Error?
    public var closureCancelMailboxChange: () -> () = {}
    public var invokedCancelMailboxChangefunction = false
    public var invokedCancelMailboxChangeCount = 0
    public var invokedCancelMailboxChangeParameters: (userId: String, mailboxId: Int)?
    public var invokedCancelMailboxChangeParametersList = [(userId: String, mailboxId: Int)]()

    public func cancelMailboxChange(userId: String, mailboxId: Int) async throws {
        invokedCancelMailboxChangefunction = true
        invokedCancelMailboxChangeCount += 1
        invokedCancelMailboxChangeParameters = (userId, mailboxId)
        invokedCancelMailboxChangeParametersList.append((userId, mailboxId))
        if let error = cancelMailboxChangeUserIdMailboxIdThrowableError5 {
            throw error
        }
        closureCancelMailboxChange()
    }
    // MARK: - getAliasSyncStatus
    public var getAliasSyncStatusUserIdThrowableError6: Error?
    public var closureGetAliasSyncStatus: () -> () = {}
    public var invokedGetAliasSyncStatusfunction = false
    public var invokedGetAliasSyncStatusCount = 0
    public var invokedGetAliasSyncStatusParameters: (userId: String, Void)?
    public var invokedGetAliasSyncStatusParametersList = [(userId: String, Void)]()
    public var stubbedGetAliasSyncStatusResult: AliasSyncStatus!

    public func getAliasSyncStatus(userId: String) async throws -> AliasSyncStatus {
        invokedGetAliasSyncStatusfunction = true
        invokedGetAliasSyncStatusCount += 1
        invokedGetAliasSyncStatusParameters = (userId, ())
        invokedGetAliasSyncStatusParametersList.append((userId, ()))
        if let error = getAliasSyncStatusUserIdThrowableError6 {
            throw error
        }
        closureGetAliasSyncStatus()
        return stubbedGetAliasSyncStatusResult
    }
    // MARK: - enableSlAliasSync
    public var enableSlAliasSyncUserIdDefaultShareIDThrowableError7: Error?
    public var closureEnableSlAliasSync: () -> () = {}
    public var invokedEnableSlAliasSyncfunction = false
    public var invokedEnableSlAliasSyncCount = 0
    public var invokedEnableSlAliasSyncParameters: (userId: String, defaultShareID: String?)?
    public var invokedEnableSlAliasSyncParametersList = [(userId: String, defaultShareID: String?)]()

    public func enableSlAliasSync(userId: String, defaultShareID: String?) async throws {
        invokedEnableSlAliasSyncfunction = true
        invokedEnableSlAliasSyncCount += 1
        invokedEnableSlAliasSyncParameters = (userId, defaultShareID)
        invokedEnableSlAliasSyncParametersList.append((userId, defaultShareID))
        if let error = enableSlAliasSyncUserIdDefaultShareIDThrowableError7 {
            throw error
        }
        closureEnableSlAliasSync()
    }
    // MARK: - updateSlAliasName
    public var updateSlAliasNameUserIdShareIdItemIdNameThrowableError8: Error?
    public var closureUpdateSlAliasName: () -> () = {}
    public var invokedUpdateSlAliasNamefunction = false
    public var invokedUpdateSlAliasNameCount = 0
    public var invokedUpdateSlAliasNameParameters: (userId: String, shareId: String, itemId: String, name: String?)?
    public var invokedUpdateSlAliasNameParametersList = [(userId: String, shareId: String, itemId: String, name: String?)]()

    public func updateSlAliasName(userId: String, shareId: String, itemId: String, name: String?) async throws {
        invokedUpdateSlAliasNamefunction = true
        invokedUpdateSlAliasNameCount += 1
        invokedUpdateSlAliasNameParameters = (userId, shareId, itemId, name)
        invokedUpdateSlAliasNameParametersList.append((userId, shareId, itemId, name))
        if let error = updateSlAliasNameUserIdShareIdItemIdNameThrowableError8 {
            throw error
        }
        closureUpdateSlAliasName()
    }
    // MARK: - updateSlAliasNote
    public var updateSlAliasNoteUserIdShareIdItemIdNoteThrowableError9: Error?
    public var closureUpdateSlAliasNote: () -> () = {}
    public var invokedUpdateSlAliasNotefunction = false
    public var invokedUpdateSlAliasNoteCount = 0
    public var invokedUpdateSlAliasNoteParameters: (userId: String, shareId: String, itemId: String, note: String?)?
    public var invokedUpdateSlAliasNoteParametersList = [(userId: String, shareId: String, itemId: String, note: String?)]()

    public func updateSlAliasNote(userId: String, shareId: String, itemId: String, note: String?) async throws {
        invokedUpdateSlAliasNotefunction = true
        invokedUpdateSlAliasNoteCount += 1
        invokedUpdateSlAliasNoteParameters = (userId, shareId, itemId, note)
        invokedUpdateSlAliasNoteParametersList.append((userId, shareId, itemId, note))
        if let error = updateSlAliasNoteUserIdShareIdItemIdNoteThrowableError9 {
            throw error
        }
        closureUpdateSlAliasNote()
    }
    // MARK: - getPendingAliasesToSync
    public var getPendingAliasesToSyncUserIdSincePageSizeThrowableError10: Error?
    public var closureGetPendingAliasesToSync: () -> () = {}
    public var invokedGetPendingAliasesToSyncfunction = false
    public var invokedGetPendingAliasesToSyncCount = 0
    public var invokedGetPendingAliasesToSyncParameters: (userId: String, since: String?, pageSize: Int)?
    public var invokedGetPendingAliasesToSyncParametersList = [(userId: String, since: String?, pageSize: Int)]()
    public var stubbedGetPendingAliasesToSyncResult: PaginatedPendingAliases!

    public func getPendingAliasesToSync(userId: String, since: String?, pageSize: Int) async throws -> PaginatedPendingAliases {
        invokedGetPendingAliasesToSyncfunction = true
        invokedGetPendingAliasesToSyncCount += 1
        invokedGetPendingAliasesToSyncParameters = (userId, since, pageSize)
        invokedGetPendingAliasesToSyncParametersList.append((userId, since, pageSize))
        if let error = getPendingAliasesToSyncUserIdSincePageSizeThrowableError10 {
            throw error
        }
        closureGetPendingAliasesToSync()
        return stubbedGetPendingAliasesToSyncResult
    }
    // MARK: - getAliasSettings
    public var getAliasSettingsUserIdThrowableError11: Error?
    public var closureGetAliasSettings: () -> () = {}
    public var invokedGetAliasSettingsfunction = false
    public var invokedGetAliasSettingsCount = 0
    public var invokedGetAliasSettingsParameters: (userId: String, Void)?
    public var invokedGetAliasSettingsParametersList = [(userId: String, Void)]()
    public var stubbedGetAliasSettingsResult: AliasSettings!

    public func getAliasSettings(userId: String) async throws -> AliasSettings {
        invokedGetAliasSettingsfunction = true
        invokedGetAliasSettingsCount += 1
        invokedGetAliasSettingsParameters = (userId, ())
        invokedGetAliasSettingsParametersList.append((userId, ()))
        if let error = getAliasSettingsUserIdThrowableError11 {
            throw error
        }
        closureGetAliasSettings()
        return stubbedGetAliasSettingsResult
    }
    // MARK: - updateAliasDefaultDomain
    public var updateAliasDefaultDomainUserIdRequestThrowableError12: Error?
    public var closureUpdateAliasDefaultDomain: () -> () = {}
    public var invokedUpdateAliasDefaultDomainfunction = false
    public var invokedUpdateAliasDefaultDomainCount = 0
    public var invokedUpdateAliasDefaultDomainParameters: (userId: String, request: UpdateAliasDomainRequest)?
    public var invokedUpdateAliasDefaultDomainParametersList = [(userId: String, request: UpdateAliasDomainRequest)]()
    public var stubbedUpdateAliasDefaultDomainResult: AliasSettings!

    public func updateAliasDefaultDomain(userId: String, request: UpdateAliasDomainRequest) async throws -> AliasSettings {
        invokedUpdateAliasDefaultDomainfunction = true
        invokedUpdateAliasDefaultDomainCount += 1
        invokedUpdateAliasDefaultDomainParameters = (userId, request)
        invokedUpdateAliasDefaultDomainParametersList.append((userId, request))
        if let error = updateAliasDefaultDomainUserIdRequestThrowableError12 {
            throw error
        }
        closureUpdateAliasDefaultDomain()
        return stubbedUpdateAliasDefaultDomainResult
    }
    // MARK: - updateAliasDefaultMailbox
    public var updateAliasDefaultMailboxUserIdRequestThrowableError13: Error?
    public var closureUpdateAliasDefaultMailbox: () -> () = {}
    public var invokedUpdateAliasDefaultMailboxfunction = false
    public var invokedUpdateAliasDefaultMailboxCount = 0
    public var invokedUpdateAliasDefaultMailboxParameters: (userId: String, request: UpdateAliasMailboxRequest)?
    public var invokedUpdateAliasDefaultMailboxParametersList = [(userId: String, request: UpdateAliasMailboxRequest)]()
    public var stubbedUpdateAliasDefaultMailboxResult: AliasSettings!

    public func updateAliasDefaultMailbox(userId: String, request: UpdateAliasMailboxRequest) async throws -> AliasSettings {
        invokedUpdateAliasDefaultMailboxfunction = true
        invokedUpdateAliasDefaultMailboxCount += 1
        invokedUpdateAliasDefaultMailboxParameters = (userId, request)
        invokedUpdateAliasDefaultMailboxParametersList.append((userId, request))
        if let error = updateAliasDefaultMailboxUserIdRequestThrowableError13 {
            throw error
        }
        closureUpdateAliasDefaultMailbox()
        return stubbedUpdateAliasDefaultMailboxResult
    }
    // MARK: - getAllAliasDomains
    public var getAllAliasDomainsUserIdThrowableError14: Error?
    public var closureGetAllAliasDomains: () -> () = {}
    public var invokedGetAllAliasDomainsfunction = false
    public var invokedGetAllAliasDomainsCount = 0
    public var invokedGetAllAliasDomainsParameters: (userId: String, Void)?
    public var invokedGetAllAliasDomainsParametersList = [(userId: String, Void)]()
    public var stubbedGetAllAliasDomainsResult: [Domain]!

    public func getAllAliasDomains(userId: String) async throws -> [Domain] {
        invokedGetAllAliasDomainsfunction = true
        invokedGetAllAliasDomainsCount += 1
        invokedGetAllAliasDomainsParameters = (userId, ())
        invokedGetAllAliasDomainsParametersList.append((userId, ()))
        if let error = getAllAliasDomainsUserIdThrowableError14 {
            throw error
        }
        closureGetAllAliasDomains()
        return stubbedGetAllAliasDomainsResult
    }
    // MARK: - getAllAliasMailboxes
    public var getAllAliasMailboxesUserIdThrowableError15: Error?
    public var closureGetAllAliasMailboxes: () -> () = {}
    public var invokedGetAllAliasMailboxesfunction = false
    public var invokedGetAllAliasMailboxesCount = 0
    public var invokedGetAllAliasMailboxesParameters: (userId: String, Void)?
    public var invokedGetAllAliasMailboxesParametersList = [(userId: String, Void)]()
    public var stubbedGetAllAliasMailboxesResult: [Mailbox]!

    public func getAllAliasMailboxes(userId: String) async throws -> [Mailbox] {
        invokedGetAllAliasMailboxesfunction = true
        invokedGetAllAliasMailboxesCount += 1
        invokedGetAllAliasMailboxesParameters = (userId, ())
        invokedGetAllAliasMailboxesParametersList.append((userId, ()))
        if let error = getAllAliasMailboxesUserIdThrowableError15 {
            throw error
        }
        closureGetAllAliasMailboxes()
        return stubbedGetAllAliasMailboxesResult
    }
    // MARK: - createMailbox
    public var createMailboxUserIdEmailThrowableError16: Error?
    public var closureCreateMailbox: () -> () = {}
    public var invokedCreateMailboxfunction = false
    public var invokedCreateMailboxCount = 0
    public var invokedCreateMailboxParameters: (userId: String, email: String)?
    public var invokedCreateMailboxParametersList = [(userId: String, email: String)]()
    public var stubbedCreateMailboxResult: Mailbox!

    public func createMailbox(userId: String, email: String) async throws -> Mailbox {
        invokedCreateMailboxfunction = true
        invokedCreateMailboxCount += 1
        invokedCreateMailboxParameters = (userId, email)
        invokedCreateMailboxParametersList.append((userId, email))
        if let error = createMailboxUserIdEmailThrowableError16 {
            throw error
        }
        closureCreateMailbox()
        return stubbedCreateMailboxResult
    }
    // MARK: - deleteMailbox
    public var deleteMailboxUserIdMailboxIDTransferMailboxIDThrowableError17: Error?
    public var closureDeleteMailbox: () -> () = {}
    public var invokedDeleteMailboxfunction = false
    public var invokedDeleteMailboxCount = 0
    public var invokedDeleteMailboxParameters: (userId: String, mailboxID: Int, transferMailboxID: Int?)?
    public var invokedDeleteMailboxParametersList = [(userId: String, mailboxID: Int, transferMailboxID: Int?)]()

    public func deleteMailbox(userId: String, mailboxID: Int, transferMailboxID: Int?) async throws {
        invokedDeleteMailboxfunction = true
        invokedDeleteMailboxCount += 1
        invokedDeleteMailboxParameters = (userId, mailboxID, transferMailboxID)
        invokedDeleteMailboxParametersList.append((userId, mailboxID, transferMailboxID))
        if let error = deleteMailboxUserIdMailboxIDTransferMailboxIDThrowableError17 {
            throw error
        }
        closureDeleteMailbox()
    }
    // MARK: - verifyMailbox
    public var verifyMailboxUserIdMailboxIDCodeThrowableError18: Error?
    public var closureVerifyMailbox: () -> () = {}
    public var invokedVerifyMailboxfunction = false
    public var invokedVerifyMailboxCount = 0
    public var invokedVerifyMailboxParameters: (userId: String, mailboxID: Int, code: String)?
    public var invokedVerifyMailboxParametersList = [(userId: String, mailboxID: Int, code: String)]()
    public var stubbedVerifyMailboxResult: Mailbox!

    public func verifyMailbox(userId: String, mailboxID: Int, code: String) async throws -> Mailbox {
        invokedVerifyMailboxfunction = true
        invokedVerifyMailboxCount += 1
        invokedVerifyMailboxParameters = (userId, mailboxID, code)
        invokedVerifyMailboxParametersList.append((userId, mailboxID, code))
        if let error = verifyMailboxUserIdMailboxIDCodeThrowableError18 {
            throw error
        }
        closureVerifyMailbox()
        return stubbedVerifyMailboxResult
    }
    // MARK: - resendMailboxVerificationEmail
    public var resendMailboxVerificationEmailUserIdMailboxIDThrowableError19: Error?
    public var closureResendMailboxVerificationEmail: () -> () = {}
    public var invokedResendMailboxVerificationEmailfunction = false
    public var invokedResendMailboxVerificationEmailCount = 0
    public var invokedResendMailboxVerificationEmailParameters: (userId: String, mailboxID: Int)?
    public var invokedResendMailboxVerificationEmailParametersList = [(userId: String, mailboxID: Int)]()
    public var stubbedResendMailboxVerificationEmailResult: Mailbox!

    public func resendMailboxVerificationEmail(userId: String, mailboxID: Int) async throws -> Mailbox {
        invokedResendMailboxVerificationEmailfunction = true
        invokedResendMailboxVerificationEmailCount += 1
        invokedResendMailboxVerificationEmailParameters = (userId, mailboxID)
        invokedResendMailboxVerificationEmailParametersList.append((userId, mailboxID))
        if let error = resendMailboxVerificationEmailUserIdMailboxIDThrowableError19 {
            throw error
        }
        closureResendMailboxVerificationEmail()
        return stubbedResendMailboxVerificationEmailResult
    }
    // MARK: - getContacts
    public var getContactsUserIdShareIdItemIdLastContactIdThrowableError20: Error?
    public var closureGetContacts: () -> () = {}
    public var invokedGetContactsfunction = false
    public var invokedGetContactsCount = 0
    public var invokedGetContactsParameters: (userId: String, shareId: String, itemId: String, lastContactId: Int?)?
    public var invokedGetContactsParametersList = [(userId: String, shareId: String, itemId: String, lastContactId: Int?)]()
    public var stubbedGetContactsResult: PaginatedAliasContacts!

    public func getContacts(userId: String, shareId: String, itemId: String, lastContactId: Int?) async throws -> PaginatedAliasContacts {
        invokedGetContactsfunction = true
        invokedGetContactsCount += 1
        invokedGetContactsParameters = (userId, shareId, itemId, lastContactId)
        invokedGetContactsParametersList.append((userId, shareId, itemId, lastContactId))
        if let error = getContactsUserIdShareIdItemIdLastContactIdThrowableError20 {
            throw error
        }
        closureGetContacts()
        return stubbedGetContactsResult
    }
    // MARK: - createContact
    public var createContactUserIdShareIdItemIdRequestThrowableError21: Error?
    public var closureCreateContact: () -> () = {}
    public var invokedCreateContactfunction = false
    public var invokedCreateContactCount = 0
    public var invokedCreateContactParameters: (userId: String, shareId: String, itemId: String, request: CreateAContactRequest)?
    public var invokedCreateContactParametersList = [(userId: String, shareId: String, itemId: String, request: CreateAContactRequest)]()
    public var stubbedCreateContactResult: AliasContactLite!

    public func createContact(userId: String, shareId: String, itemId: String, request: CreateAContactRequest) async throws -> AliasContactLite {
        invokedCreateContactfunction = true
        invokedCreateContactCount += 1
        invokedCreateContactParameters = (userId, shareId, itemId, request)
        invokedCreateContactParametersList.append((userId, shareId, itemId, request))
        if let error = createContactUserIdShareIdItemIdRequestThrowableError21 {
            throw error
        }
        closureCreateContact()
        return stubbedCreateContactResult
    }
    // MARK: - getContactInfos
    public var getContactInfosUserIdShareIdItemIdContactIdThrowableError22: Error?
    public var closureGetContactInfos: () -> () = {}
    public var invokedGetContactInfosfunction = false
    public var invokedGetContactInfosCount = 0
    public var invokedGetContactInfosParameters: (userId: String, shareId: String, itemId: String, contactId: String)?
    public var invokedGetContactInfosParametersList = [(userId: String, shareId: String, itemId: String, contactId: String)]()
    public var stubbedGetContactInfosResult: AliasContact!

    public func getContactInfos(userId: String, shareId: String, itemId: String, contactId: String) async throws -> AliasContact {
        invokedGetContactInfosfunction = true
        invokedGetContactInfosCount += 1
        invokedGetContactInfosParameters = (userId, shareId, itemId, contactId)
        invokedGetContactInfosParametersList.append((userId, shareId, itemId, contactId))
        if let error = getContactInfosUserIdShareIdItemIdContactIdThrowableError22 {
            throw error
        }
        closureGetContactInfos()
        return stubbedGetContactInfosResult
    }
    // MARK: - updateContact
    public var updateContactUserIdShareIdItemIdContactIdBlockedThrowableError23: Error?
    public var closureUpdateContact: () -> () = {}
    public var invokedUpdateContactfunction = false
    public var invokedUpdateContactCount = 0
    public var invokedUpdateContactParameters: (userId: String, shareId: String, itemId: String, contactId: String, blocked: Bool)?
    public var invokedUpdateContactParametersList = [(userId: String, shareId: String, itemId: String, contactId: String, blocked: Bool)]()
    public var stubbedUpdateContactResult: AliasContactLite!

    public func updateContact(userId: String, shareId: String, itemId: String, contactId: String, blocked: Bool) async throws -> AliasContactLite {
        invokedUpdateContactfunction = true
        invokedUpdateContactCount += 1
        invokedUpdateContactParameters = (userId, shareId, itemId, contactId, blocked)
        invokedUpdateContactParametersList.append((userId, shareId, itemId, contactId, blocked))
        if let error = updateContactUserIdShareIdItemIdContactIdBlockedThrowableError23 {
            throw error
        }
        closureUpdateContact()
        return stubbedUpdateContactResult
    }
    // MARK: - deleteContact
    public var deleteContactUserIdShareIdItemIdContactIdThrowableError24: Error?
    public var closureDeleteContact: () -> () = {}
    public var invokedDeleteContactfunction = false
    public var invokedDeleteContactCount = 0
    public var invokedDeleteContactParameters: (userId: String, shareId: String, itemId: String, contactId: String)?
    public var invokedDeleteContactParametersList = [(userId: String, shareId: String, itemId: String, contactId: String)]()

    public func deleteContact(userId: String, shareId: String, itemId: String, contactId: String) async throws {
        invokedDeleteContactfunction = true
        invokedDeleteContactCount += 1
        invokedDeleteContactParameters = (userId, shareId, itemId, contactId)
        invokedDeleteContactParametersList.append((userId, shareId, itemId, contactId))
        if let error = deleteContactUserIdShareIdItemIdContactIdThrowableError24 {
            throw error
        }
        closureDeleteContact()
    }
}
