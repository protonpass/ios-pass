// Generated using Sourcery 2.2.3 — https://github.com/krzysztofzablocki/Sourcery
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
import Entities

public final class RemoteBreachDataSourceProtocolMock: @unchecked Sendable, RemoteBreachDataSourceProtocol {

    public init() {}

    // MARK: - getAllBreachesForUser
    public var getAllBreachesForUserThrowableError1: Error?
    public var closureGetAllBreachesForUser: () -> () = {}
    public var invokedGetAllBreachesForUserfunction = false
    public var invokedGetAllBreachesForUserCount = 0
    public var stubbedGetAllBreachesForUserResult: UserBreaches!

    public func getAllBreachesForUser() async throws -> UserBreaches {
        invokedGetAllBreachesForUserfunction = true
        invokedGetAllBreachesForUserCount += 1
        if let error = getAllBreachesForUserThrowableError1 {
            throw error
        }
        closureGetAllBreachesForUser()
        return stubbedGetAllBreachesForUserResult
    }
    // MARK: - getAllCustomEmailForUser
    public var getAllCustomEmailForUserThrowableError2: Error?
    public var closureGetAllCustomEmailForUser: () -> () = {}
    public var invokedGetAllCustomEmailForUserfunction = false
    public var invokedGetAllCustomEmailForUserCount = 0
    public var stubbedGetAllCustomEmailForUserResult: [CustomEmail]!

    public func getAllCustomEmailForUser() async throws -> [CustomEmail] {
        invokedGetAllCustomEmailForUserfunction = true
        invokedGetAllCustomEmailForUserCount += 1
        if let error = getAllCustomEmailForUserThrowableError2 {
            throw error
        }
        closureGetAllCustomEmailForUser()
        return stubbedGetAllCustomEmailForUserResult
    }
    // MARK: - addEmailToBreachMonitoring
    public var addEmailToBreachMonitoringEmailThrowableError3: Error?
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
        if let error = addEmailToBreachMonitoringEmailThrowableError3 {
            throw error
        }
        closureAddEmailToBreachMonitoring()
        return stubbedAddEmailToBreachMonitoringResult
    }
    // MARK: - verifyCustomEmail
    public var verifyCustomEmailEmailIdCodeThrowableError4: Error?
    public var closureVerifyCustomEmail: () -> () = {}
    public var invokedVerifyCustomEmailfunction = false
    public var invokedVerifyCustomEmailCount = 0
    public var invokedVerifyCustomEmailParameters: (emailId: String, code: String)?
    public var invokedVerifyCustomEmailParametersList = [(emailId: String, code: String)]()

    public func verifyCustomEmail(emailId: String, code: String) async throws {
        invokedVerifyCustomEmailfunction = true
        invokedVerifyCustomEmailCount += 1
        invokedVerifyCustomEmailParameters = (emailId, code)
        invokedVerifyCustomEmailParametersList.append((emailId, code))
        if let error = verifyCustomEmailEmailIdCodeThrowableError4 {
            throw error
        }
        closureVerifyCustomEmail()
    }
    // MARK: - getAllBreachesForEmail
    public var getAllBreachesForEmailEmailThrowableError5: Error?
    public var closureGetAllBreachesForEmail: () -> () = {}
    public var invokedGetAllBreachesForEmailfunction = false
    public var invokedGetAllBreachesForEmailCount = 0
    public var invokedGetAllBreachesForEmailParameters: (email: CustomEmail, Void)?
    public var invokedGetAllBreachesForEmailParametersList = [(email: CustomEmail, Void)]()
    public var stubbedGetAllBreachesForEmailResult: EmailBreaches!

    public func getAllBreachesForEmail(email: CustomEmail) async throws -> EmailBreaches {
        invokedGetAllBreachesForEmailfunction = true
        invokedGetAllBreachesForEmailCount += 1
        invokedGetAllBreachesForEmailParameters = (email, ())
        invokedGetAllBreachesForEmailParametersList.append((email, ()))
        if let error = getAllBreachesForEmailEmailThrowableError5 {
            throw error
        }
        closureGetAllBreachesForEmail()
        return stubbedGetAllBreachesForEmailResult
    }
    // MARK: - getAllBreachesForProtonAddress
    public var getAllBreachesForProtonAddressAddressThrowableError6: Error?
    public var closureGetAllBreachesForProtonAddress: () -> () = {}
    public var invokedGetAllBreachesForProtonAddressfunction = false
    public var invokedGetAllBreachesForProtonAddressCount = 0
    public var invokedGetAllBreachesForProtonAddressParameters: (address: ProtonAddress, Void)?
    public var invokedGetAllBreachesForProtonAddressParametersList = [(address: ProtonAddress, Void)]()
    public var stubbedGetAllBreachesForProtonAddressResult: EmailBreaches!

    public func getAllBreachesForProtonAddress(address: ProtonAddress) async throws -> EmailBreaches {
        invokedGetAllBreachesForProtonAddressfunction = true
        invokedGetAllBreachesForProtonAddressCount += 1
        invokedGetAllBreachesForProtonAddressParameters = (address, ())
        invokedGetAllBreachesForProtonAddressParametersList.append((address, ()))
        if let error = getAllBreachesForProtonAddressAddressThrowableError6 {
            throw error
        }
        closureGetAllBreachesForProtonAddress()
        return stubbedGetAllBreachesForProtonAddressResult
    }
    // MARK: - removeEmailFromBreachMonitoring
    public var removeEmailFromBreachMonitoringEmailIdThrowableError7: Error?
    public var closureRemoveEmailFromBreachMonitoring: () -> () = {}
    public var invokedRemoveEmailFromBreachMonitoringfunction = false
    public var invokedRemoveEmailFromBreachMonitoringCount = 0
    public var invokedRemoveEmailFromBreachMonitoringParameters: (emailId: String, Void)?
    public var invokedRemoveEmailFromBreachMonitoringParametersList = [(emailId: String, Void)]()

    public func removeEmailFromBreachMonitoring(emailId: String) async throws {
        invokedRemoveEmailFromBreachMonitoringfunction = true
        invokedRemoveEmailFromBreachMonitoringCount += 1
        invokedRemoveEmailFromBreachMonitoringParameters = (emailId, ())
        invokedRemoveEmailFromBreachMonitoringParametersList.append((emailId, ()))
        if let error = removeEmailFromBreachMonitoringEmailIdThrowableError7 {
            throw error
        }
        closureRemoveEmailFromBreachMonitoring()
    }
    // MARK: - getBreachesForAlias
    public var getBreachesForAliasSharedIdItemIdThrowableError8: Error?
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
        if let error = getBreachesForAliasSharedIdItemIdThrowableError8 {
            throw error
        }
        closureGetBreachesForAlias()
        return stubbedGetBreachesForAliasResult
    }
    // MARK: - resendEmailVerification
    public var resendEmailVerificationEmailIdThrowableError9: Error?
    public var closureResendEmailVerification: () -> () = {}
    public var invokedResendEmailVerificationfunction = false
    public var invokedResendEmailVerificationCount = 0
    public var invokedResendEmailVerificationParameters: (emailId: String, Void)?
    public var invokedResendEmailVerificationParametersList = [(emailId: String, Void)]()

    public func resendEmailVerification(emailId: String) async throws {
        invokedResendEmailVerificationfunction = true
        invokedResendEmailVerificationCount += 1
        invokedResendEmailVerificationParameters = (emailId, ())
        invokedResendEmailVerificationParametersList.append((emailId, ()))
        if let error = resendEmailVerificationEmailIdThrowableError9 {
            throw error
        }
        closureResendEmailVerification()
    }
    // MARK: - markAliasAsResolved
    public var markAliasAsResolvedSharedIdItemIdThrowableError10: Error?
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
        if let error = markAliasAsResolvedSharedIdItemIdThrowableError10 {
            throw error
        }
        closureMarkAliasAsResolved()
    }
    // MARK: - markProtonAddressAsResolved
    public var markProtonAddressAsResolvedAddressThrowableError11: Error?
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
        if let error = markProtonAddressAsResolvedAddressThrowableError11 {
            throw error
        }
        closureMarkProtonAddressAsResolved()
    }
    // MARK: - markCustomEmailAsResolved
    public var markCustomEmailAsResolvedEmailThrowableError12: Error?
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
        if let error = markCustomEmailAsResolvedEmailThrowableError12 {
            throw error
        }
        closureMarkCustomEmailAsResolved()
        return stubbedMarkCustomEmailAsResolvedResult
    }
    // MARK: - toggleMonitoringForAddressShouldMonitor
    public var toggleMonitoringForAddressShouldMonitorThrowableError13: Error?
    public var closureToggleMonitoringForAddressShouldMonitorAsync13: () -> () = {}
    public var invokedToggleMonitoringForAddressShouldMonitorAsync13 = false
    public var invokedToggleMonitoringForAddressShouldMonitorAsyncCount13 = 0
    public var invokedToggleMonitoringForAddressShouldMonitorAsyncParameters13: (address: ProtonAddress, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForAddressShouldMonitorAsyncParametersList13 = [(address: ProtonAddress, shouldMonitor: Bool)]()

    public func toggleMonitoringFor(address: ProtonAddress, shouldMonitor: Bool) async throws {
        invokedToggleMonitoringForAddressShouldMonitorAsync13 = true
        invokedToggleMonitoringForAddressShouldMonitorAsyncCount13 += 1
        invokedToggleMonitoringForAddressShouldMonitorAsyncParameters13 = (address, shouldMonitor)
        invokedToggleMonitoringForAddressShouldMonitorAsyncParametersList13.append((address, shouldMonitor))
        if let error = toggleMonitoringForAddressShouldMonitorThrowableError13 {
            throw error
        }
        closureToggleMonitoringForAddressShouldMonitorAsync13()
    }
    // MARK: - toggleMonitoringForEmailShouldMonitor
    public var toggleMonitoringForEmailShouldMonitorThrowableError14: Error?
    public var closureToggleMonitoringForEmailShouldMonitorAsync14: () -> () = {}
    public var invokedToggleMonitoringForEmailShouldMonitorAsync14 = false
    public var invokedToggleMonitoringForEmailShouldMonitorAsyncCount14 = 0
    public var invokedToggleMonitoringForEmailShouldMonitorAsyncParameters14: (email: CustomEmail, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForEmailShouldMonitorAsyncParametersList14 = [(email: CustomEmail, shouldMonitor: Bool)]()
    public var stubbedToggleMonitoringForEmailShouldMonitorAsyncResult14: CustomEmail!

    public func toggleMonitoringFor(email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail {
        invokedToggleMonitoringForEmailShouldMonitorAsync14 = true
        invokedToggleMonitoringForEmailShouldMonitorAsyncCount14 += 1
        invokedToggleMonitoringForEmailShouldMonitorAsyncParameters14 = (email, shouldMonitor)
        invokedToggleMonitoringForEmailShouldMonitorAsyncParametersList14.append((email, shouldMonitor))
        if let error = toggleMonitoringForEmailShouldMonitorThrowableError14 {
            throw error
        }
        closureToggleMonitoringForEmailShouldMonitorAsync14()
        return stubbedToggleMonitoringForEmailShouldMonitorAsyncResult14
    }
}
