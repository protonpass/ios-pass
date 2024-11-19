// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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
import CryptoKit
import Entities
import Foundation
import PassRustCore

public final class PassMonitorRepositoryProtocolMock: @unchecked Sendable, PassMonitorRepositoryProtocol {

    public init() {}

    // MARK: - darkWebDataSectionUpdate
    public var invokedDarkWebDataSectionUpdateSetter = false
    public var invokedDarkWebDataSectionUpdateSetterCount = 0
    public var invokedDarkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never>?
    public var invokedDarkWebDataSectionUpdateList = [PassthroughSubject<DarkWebDataSectionUpdate, Never>?]()
    public var invokedDarkWebDataSectionUpdateGetter = false
    public var invokedDarkWebDataSectionUpdateGetterCount = 0
    public var stubbedDarkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never>!
    public var darkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never> {
        set {
            invokedDarkWebDataSectionUpdateSetter = true
            invokedDarkWebDataSectionUpdateSetterCount += 1
            invokedDarkWebDataSectionUpdate = newValue
            invokedDarkWebDataSectionUpdateList.append(newValue)
        } get {
            invokedDarkWebDataSectionUpdateGetter = true
            invokedDarkWebDataSectionUpdateGetterCount += 1
            return stubbedDarkWebDataSectionUpdate
        }
    }
    // MARK: - userBreaches
    public var invokedUserBreachesSetter = false
    public var invokedUserBreachesSetterCount = 0
    public var invokedUserBreaches: CurrentValueSubject<UserBreaches?, Never>?
    public var invokedUserBreachesList = [CurrentValueSubject<UserBreaches?, Never>?]()
    public var invokedUserBreachesGetter = false
    public var invokedUserBreachesGetterCount = 0
    public var stubbedUserBreaches: CurrentValueSubject<UserBreaches?, Never>!
    public var userBreaches: CurrentValueSubject<UserBreaches?, Never> {
        set {
            invokedUserBreachesSetter = true
            invokedUserBreachesSetterCount += 1
            invokedUserBreaches = newValue
            invokedUserBreachesList.append(newValue)
        } get {
            invokedUserBreachesGetter = true
            invokedUserBreachesGetterCount += 1
            return stubbedUserBreaches
        }
    }
    // MARK: - weaknessStats
    public var invokedWeaknessStatsSetter = false
    public var invokedWeaknessStatsSetterCount = 0
    public var invokedWeaknessStats: CurrentValueSubject<WeaknessStats, Never>?
    public var invokedWeaknessStatsList = [CurrentValueSubject<WeaknessStats, Never>?]()
    public var invokedWeaknessStatsGetter = false
    public var invokedWeaknessStatsGetterCount = 0
    public var stubbedWeaknessStats: CurrentValueSubject<WeaknessStats, Never>!
    public var weaknessStats: CurrentValueSubject<WeaknessStats, Never> {
        set {
            invokedWeaknessStatsSetter = true
            invokedWeaknessStatsSetterCount += 1
            invokedWeaknessStats = newValue
            invokedWeaknessStatsList.append(newValue)
        } get {
            invokedWeaknessStatsGetter = true
            invokedWeaknessStatsGetterCount += 1
            return stubbedWeaknessStats
        }
    }
    // MARK: - itemsWithSecurityIssues
    public var invokedItemsWithSecurityIssuesSetter = false
    public var invokedItemsWithSecurityIssuesSetterCount = 0
    public var invokedItemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never>?
    public var invokedItemsWithSecurityIssuesList = [CurrentValueSubject<[SecurityAffectedItem], Never>?]()
    public var invokedItemsWithSecurityIssuesGetter = false
    public var invokedItemsWithSecurityIssuesGetterCount = 0
    public var stubbedItemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never>!
    public var itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> {
        set {
            invokedItemsWithSecurityIssuesSetter = true
            invokedItemsWithSecurityIssuesSetterCount += 1
            invokedItemsWithSecurityIssues = newValue
            invokedItemsWithSecurityIssuesList.append(newValue)
        } get {
            invokedItemsWithSecurityIssuesGetter = true
            invokedItemsWithSecurityIssuesGetterCount += 1
            return stubbedItemsWithSecurityIssues
        }
    }
    // MARK: - refreshSecurityChecks
    public var refreshSecurityChecksThrowableError1: Error?
    public var closureRefreshSecurityChecks: () -> () = {}
    public var invokedRefreshSecurityChecksfunction = false
    public var invokedRefreshSecurityChecksCount = 0

    public func refreshSecurityChecks() async throws {
        invokedRefreshSecurityChecksfunction = true
        invokedRefreshSecurityChecksCount += 1
        if let error = refreshSecurityChecksThrowableError1 {
            throw error
        }
        closureRefreshSecurityChecks()
    }
    // MARK: - getItemsWithSamePassword
    public var getItemsWithSamePasswordItemThrowableError2: Error?
    public var closureGetItemsWithSamePassword: () -> () = {}
    public var invokedGetItemsWithSamePasswordfunction = false
    public var invokedGetItemsWithSamePasswordCount = 0
    public var invokedGetItemsWithSamePasswordParameters: (item: ItemContent, Void)?
    public var invokedGetItemsWithSamePasswordParametersList = [(item: ItemContent, Void)]()
    public var stubbedGetItemsWithSamePasswordResult: [ItemContent]!

    public func getItemsWithSamePassword(item: ItemContent) async throws -> [ItemContent] {
        invokedGetItemsWithSamePasswordfunction = true
        invokedGetItemsWithSamePasswordCount += 1
        invokedGetItemsWithSamePasswordParameters = (item, ())
        invokedGetItemsWithSamePasswordParametersList.append((item, ()))
        if let error = getItemsWithSamePasswordItemThrowableError2 {
            throw error
        }
        closureGetItemsWithSamePassword()
        return stubbedGetItemsWithSamePasswordResult
    }
    // MARK: - reset
    public var closureReset: () -> () = {}
    public var invokedResetfunction = false
    public var invokedResetCount = 0

    public func reset() async {
        invokedResetfunction = true
        invokedResetCount += 1
        closureReset()
    }
    // MARK: - refreshUserBreaches
    public var refreshUserBreachesThrowableError4: Error?
    public var closureRefreshUserBreaches: () -> () = {}
    public var invokedRefreshUserBreachesfunction = false
    public var invokedRefreshUserBreachesCount = 0
    public var stubbedRefreshUserBreachesResult: UserBreaches!

    public func refreshUserBreaches() async throws -> UserBreaches {
        invokedRefreshUserBreachesfunction = true
        invokedRefreshUserBreachesCount += 1
        if let error = refreshUserBreachesThrowableError4 {
            throw error
        }
        closureRefreshUserBreaches()
        return stubbedRefreshUserBreachesResult
    }
    // MARK: - getAllCustomEmailForUser
    public var getAllCustomEmailForUserThrowableError5: Error?
    public var closureGetAllCustomEmailForUser: () -> () = {}
    public var invokedGetAllCustomEmailForUserfunction = false
    public var invokedGetAllCustomEmailForUserCount = 0
    public var stubbedGetAllCustomEmailForUserResult: [CustomEmail]!

    public func getAllCustomEmailForUser() async throws -> [CustomEmail] {
        invokedGetAllCustomEmailForUserfunction = true
        invokedGetAllCustomEmailForUserCount += 1
        if let error = getAllCustomEmailForUserThrowableError5 {
            throw error
        }
        closureGetAllCustomEmailForUser()
        return stubbedGetAllCustomEmailForUserResult
    }
    // MARK: - addEmailToBreachMonitoring
    public var addEmailToBreachMonitoringEmailThrowableError6: Error?
    public var closureAddEmailToBreachMonitoring: () -> () = {}
    public var invokedAddEmailToBreachMonitoringfunction = false
    public var invokedAddEmailToBreachMonitoringCount = 0
    public var invokedAddEmailToBreachMonitoringParameters: (email: String, Void)?
    public var invokedAddEmailToBreachMonitoringParametersList = [(email: String, Void)]()
    public var stubbedAddEmailToBreachMonitoringResult: CustomEmail!

    public func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail {
        invokedAddEmailToBreachMonitoringfunction = true
        invokedAddEmailToBreachMonitoringCount += 1
        invokedAddEmailToBreachMonitoringParameters = (email, ())
        invokedAddEmailToBreachMonitoringParametersList.append((email, ()))
        if let error = addEmailToBreachMonitoringEmailThrowableError6 {
            throw error
        }
        closureAddEmailToBreachMonitoring()
        return stubbedAddEmailToBreachMonitoringResult
    }
    // MARK: - verifyCustomEmail
    public var verifyCustomEmailEmailCodeThrowableError7: Error?
    public var closureVerifyCustomEmail: () -> () = {}
    public var invokedVerifyCustomEmailfunction = false
    public var invokedVerifyCustomEmailCount = 0
    public var invokedVerifyCustomEmailParameters: (email: CustomEmail, code: String)?
    public var invokedVerifyCustomEmailParametersList = [(email: CustomEmail, code: String)]()

    public func verifyCustomEmail(email: CustomEmail, code: String) async throws {
        invokedVerifyCustomEmailfunction = true
        invokedVerifyCustomEmailCount += 1
        invokedVerifyCustomEmailParameters = (email, code)
        invokedVerifyCustomEmailParametersList.append((email, code))
        if let error = verifyCustomEmailEmailCodeThrowableError7 {
            throw error
        }
        closureVerifyCustomEmail()
    }
    // MARK: - removeEmailFromBreachMonitoring
    public var removeEmailFromBreachMonitoringEmailThrowableError8: Error?
    public var closureRemoveEmailFromBreachMonitoring: () -> () = {}
    public var invokedRemoveEmailFromBreachMonitoringfunction = false
    public var invokedRemoveEmailFromBreachMonitoringCount = 0
    public var invokedRemoveEmailFromBreachMonitoringParameters: (email: CustomEmail, Void)?
    public var invokedRemoveEmailFromBreachMonitoringParametersList = [(email: CustomEmail, Void)]()

    public func removeEmailFromBreachMonitoring(email: CustomEmail) async throws {
        invokedRemoveEmailFromBreachMonitoringfunction = true
        invokedRemoveEmailFromBreachMonitoringCount += 1
        invokedRemoveEmailFromBreachMonitoringParameters = (email, ())
        invokedRemoveEmailFromBreachMonitoringParametersList.append((email, ()))
        if let error = removeEmailFromBreachMonitoringEmailThrowableError8 {
            throw error
        }
        closureRemoveEmailFromBreachMonitoring()
    }
    // MARK: - resendEmailVerification
    public var resendEmailVerificationEmailThrowableError9: Error?
    public var closureResendEmailVerification: () -> () = {}
    public var invokedResendEmailVerificationfunction = false
    public var invokedResendEmailVerificationCount = 0
    public var invokedResendEmailVerificationParameters: (email: CustomEmail, Void)?
    public var invokedResendEmailVerificationParametersList = [(email: CustomEmail, Void)]()

    public func resendEmailVerification(email: CustomEmail) async throws {
        invokedResendEmailVerificationfunction = true
        invokedResendEmailVerificationCount += 1
        invokedResendEmailVerificationParameters = (email, ())
        invokedResendEmailVerificationParametersList.append((email, ()))
        if let error = resendEmailVerificationEmailThrowableError9 {
            throw error
        }
        closureResendEmailVerification()
    }
    // MARK: - getBreachesForAlias
    public var getBreachesForAliasSharedIdItemIdThrowableError10: Error?
    public var closureGetBreachesForAlias: () -> () = {}
    public var invokedGetBreachesForAliasfunction = false
    public var invokedGetBreachesForAliasCount = 0
    public var invokedGetBreachesForAliasParameters: (sharedId: String, itemId: String)?
    public var invokedGetBreachesForAliasParametersList = [(sharedId: String, itemId: String)]()
    public var stubbedGetBreachesForAliasResult: EmailBreaches!

    public func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches {
        invokedGetBreachesForAliasfunction = true
        invokedGetBreachesForAliasCount += 1
        invokedGetBreachesForAliasParameters = (sharedId, itemId)
        invokedGetBreachesForAliasParametersList.append((sharedId, itemId))
        if let error = getBreachesForAliasSharedIdItemIdThrowableError10 {
            throw error
        }
        closureGetBreachesForAlias()
        return stubbedGetBreachesForAliasResult
    }
    // MARK: - getAllBreachesForEmail
    public var getAllBreachesForEmailEmailIdThrowableError11: Error?
    public var closureGetAllBreachesForEmail: () -> () = {}
    public var invokedGetAllBreachesForEmailfunction = false
    public var invokedGetAllBreachesForEmailCount = 0
    public var invokedGetAllBreachesForEmailParameters: (emailId: String, Void)?
    public var invokedGetAllBreachesForEmailParametersList = [(emailId: String, Void)]()
    public var stubbedGetAllBreachesForEmailResult: EmailBreaches!

    public func getAllBreachesForEmail(emailId: String) async throws -> EmailBreaches {
        invokedGetAllBreachesForEmailfunction = true
        invokedGetAllBreachesForEmailCount += 1
        invokedGetAllBreachesForEmailParameters = (emailId, ())
        invokedGetAllBreachesForEmailParametersList.append((emailId, ()))
        if let error = getAllBreachesForEmailEmailIdThrowableError11 {
            throw error
        }
        closureGetAllBreachesForEmail()
        return stubbedGetAllBreachesForEmailResult
    }
    // MARK: - getAllBreachesForProtonAddress
    public var getAllBreachesForProtonAddressAddressIdThrowableError12: Error?
    public var closureGetAllBreachesForProtonAddress: () -> () = {}
    public var invokedGetAllBreachesForProtonAddressfunction = false
    public var invokedGetAllBreachesForProtonAddressCount = 0
    public var invokedGetAllBreachesForProtonAddressParameters: (addressId: String, Void)?
    public var invokedGetAllBreachesForProtonAddressParametersList = [(addressId: String, Void)]()
    public var stubbedGetAllBreachesForProtonAddressResult: EmailBreaches!

    public func getAllBreachesForProtonAddress(addressId: String) async throws -> EmailBreaches {
        invokedGetAllBreachesForProtonAddressfunction = true
        invokedGetAllBreachesForProtonAddressCount += 1
        invokedGetAllBreachesForProtonAddressParameters = (addressId, ())
        invokedGetAllBreachesForProtonAddressParametersList.append((addressId, ()))
        if let error = getAllBreachesForProtonAddressAddressIdThrowableError12 {
            throw error
        }
        closureGetAllBreachesForProtonAddress()
        return stubbedGetAllBreachesForProtonAddressResult
    }
    // MARK: - markAliasAsResolved
    public var markAliasAsResolvedSharedIdItemIdThrowableError13: Error?
    public var closureMarkAliasAsResolved: () -> () = {}
    public var invokedMarkAliasAsResolvedfunction = false
    public var invokedMarkAliasAsResolvedCount = 0
    public var invokedMarkAliasAsResolvedParameters: (sharedId: String, itemId: String)?
    public var invokedMarkAliasAsResolvedParametersList = [(sharedId: String, itemId: String)]()

    public func markAliasAsResolved(sharedId: String, itemId: String) async throws {
        invokedMarkAliasAsResolvedfunction = true
        invokedMarkAliasAsResolvedCount += 1
        invokedMarkAliasAsResolvedParameters = (sharedId, itemId)
        invokedMarkAliasAsResolvedParametersList.append((sharedId, itemId))
        if let error = markAliasAsResolvedSharedIdItemIdThrowableError13 {
            throw error
        }
        closureMarkAliasAsResolved()
    }
    // MARK: - markProtonAddressAsResolved
    public var markProtonAddressAsResolvedAddressThrowableError14: Error?
    public var closureMarkProtonAddressAsResolved: () -> () = {}
    public var invokedMarkProtonAddressAsResolvedfunction = false
    public var invokedMarkProtonAddressAsResolvedCount = 0
    public var invokedMarkProtonAddressAsResolvedParameters: (address: ProtonAddress, Void)?
    public var invokedMarkProtonAddressAsResolvedParametersList = [(address: ProtonAddress, Void)]()

    public func markProtonAddressAsResolved(address: ProtonAddress) async throws {
        invokedMarkProtonAddressAsResolvedfunction = true
        invokedMarkProtonAddressAsResolvedCount += 1
        invokedMarkProtonAddressAsResolvedParameters = (address, ())
        invokedMarkProtonAddressAsResolvedParametersList.append((address, ()))
        if let error = markProtonAddressAsResolvedAddressThrowableError14 {
            throw error
        }
        closureMarkProtonAddressAsResolved()
    }
    // MARK: - markCustomEmailAsResolved
    public var markCustomEmailAsResolvedEmailThrowableError15: Error?
    public var closureMarkCustomEmailAsResolved: () -> () = {}
    public var invokedMarkCustomEmailAsResolvedfunction = false
    public var invokedMarkCustomEmailAsResolvedCount = 0
    public var invokedMarkCustomEmailAsResolvedParameters: (email: CustomEmail, Void)?
    public var invokedMarkCustomEmailAsResolvedParametersList = [(email: CustomEmail, Void)]()
    public var stubbedMarkCustomEmailAsResolvedResult: CustomEmail!

    public func markCustomEmailAsResolved(email: CustomEmail) async throws -> CustomEmail {
        invokedMarkCustomEmailAsResolvedfunction = true
        invokedMarkCustomEmailAsResolvedCount += 1
        invokedMarkCustomEmailAsResolvedParameters = (email, ())
        invokedMarkCustomEmailAsResolvedParametersList.append((email, ()))
        if let error = markCustomEmailAsResolvedEmailThrowableError15 {
            throw error
        }
        closureMarkCustomEmailAsResolved()
        return stubbedMarkCustomEmailAsResolvedResult
    }
    // MARK: - toggleMonitoringForAddressShouldMonitor
    public var toggleMonitoringForAddressShouldMonitorThrowableError16: Error?
    public var closureToggleMonitoringForAddressShouldMonitorAsync16: () -> () = {}
    public var invokedToggleMonitoringForAddressShouldMonitorAsync16 = false
    public var invokedToggleMonitoringForAddressShouldMonitorAsyncCount16 = 0
    public var invokedToggleMonitoringForAddressShouldMonitorAsyncParameters16: (address: ProtonAddress, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForAddressShouldMonitorAsyncParametersList16 = [(address: ProtonAddress, shouldMonitor: Bool)]()

    public func toggleMonitoringFor(address: ProtonAddress, shouldMonitor: Bool) async throws {
        invokedToggleMonitoringForAddressShouldMonitorAsync16 = true
        invokedToggleMonitoringForAddressShouldMonitorAsyncCount16 += 1
        invokedToggleMonitoringForAddressShouldMonitorAsyncParameters16 = (address, shouldMonitor)
        invokedToggleMonitoringForAddressShouldMonitorAsyncParametersList16.append((address, shouldMonitor))
        if let error = toggleMonitoringForAddressShouldMonitorThrowableError16 {
            throw error
        }
        closureToggleMonitoringForAddressShouldMonitorAsync16()
    }
    // MARK: - toggleMonitoringForEmailShouldMonitor
    public var toggleMonitoringForEmailShouldMonitorThrowableError17: Error?
    public var closureToggleMonitoringForEmailShouldMonitorAsync17: () -> () = {}
    public var invokedToggleMonitoringForEmailShouldMonitorAsync17 = false
    public var invokedToggleMonitoringForEmailShouldMonitorAsyncCount17 = 0
    public var invokedToggleMonitoringForEmailShouldMonitorAsyncParameters17: (email: CustomEmail, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForEmailShouldMonitorAsyncParametersList17 = [(email: CustomEmail, shouldMonitor: Bool)]()
    public var stubbedToggleMonitoringForEmailShouldMonitorAsyncResult17: CustomEmail!

    public func toggleMonitoringFor(email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail {
        invokedToggleMonitoringForEmailShouldMonitorAsync17 = true
        invokedToggleMonitoringForEmailShouldMonitorAsyncCount17 += 1
        invokedToggleMonitoringForEmailShouldMonitorAsyncParameters17 = (email, shouldMonitor)
        invokedToggleMonitoringForEmailShouldMonitorAsyncParametersList17.append((email, shouldMonitor))
        if let error = toggleMonitoringForEmailShouldMonitorThrowableError17 {
            throw error
        }
        closureToggleMonitoringForEmailShouldMonitorAsync17()
        return stubbedToggleMonitoringForEmailShouldMonitorAsyncResult17
    }
    // MARK: - toggleMonitoringForAlias
    public var toggleMonitoringForAliasSharedIdItemIdShouldMonitorThrowableError18: Error?
    public var closureToggleMonitoringForAlias: () -> () = {}
    public var invokedToggleMonitoringForAliasfunction = false
    public var invokedToggleMonitoringForAliasCount = 0
    public var invokedToggleMonitoringForAliasParameters: (sharedId: String, itemId: String, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForAliasParametersList = [(sharedId: String, itemId: String, shouldMonitor: Bool)]()

    public func toggleMonitoringForAlias(sharedId: String, itemId: String, shouldMonitor: Bool) async throws {
        invokedToggleMonitoringForAliasfunction = true
        invokedToggleMonitoringForAliasCount += 1
        invokedToggleMonitoringForAliasParameters = (sharedId, itemId, shouldMonitor)
        invokedToggleMonitoringForAliasParametersList.append((sharedId, itemId, shouldMonitor))
        if let error = toggleMonitoringForAliasSharedIdItemIdShouldMonitorThrowableError18 {
            throw error
        }
        closureToggleMonitoringForAlias()
    }
}
