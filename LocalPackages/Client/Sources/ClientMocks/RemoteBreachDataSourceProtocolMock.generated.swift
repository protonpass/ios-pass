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
import Entities

public final class RemoteBreachDataSourceProtocolMock: @unchecked Sendable, RemoteBreachDataSourceProtocol {

    public init() {}

    // MARK: - getAllBreachesForUser
    public var getAllBreachesForUserUserIdThrowableError1: Error?
    public var closureGetAllBreachesForUser: () -> () = {}
    public var invokedGetAllBreachesForUserfunction = false
    public var invokedGetAllBreachesForUserCount = 0
    public var invokedGetAllBreachesForUserParameters: (userId: String, Void)?
    public var invokedGetAllBreachesForUserParametersList = [(userId: String, Void)]()
    public var stubbedGetAllBreachesForUserResult: UserBreaches!

    public func getAllBreachesForUser(userId: String) async throws -> UserBreaches {
        invokedGetAllBreachesForUserfunction = true
        invokedGetAllBreachesForUserCount += 1
        invokedGetAllBreachesForUserParameters = (userId, ())
        invokedGetAllBreachesForUserParametersList.append((userId, ()))
        if let error = getAllBreachesForUserUserIdThrowableError1 {
            throw error
        }
        closureGetAllBreachesForUser()
        return stubbedGetAllBreachesForUserResult
    }
    // MARK: - getAllCustomEmailForUser
    public var getAllCustomEmailForUserUserIdThrowableError2: Error?
    public var closureGetAllCustomEmailForUser: () -> () = {}
    public var invokedGetAllCustomEmailForUserfunction = false
    public var invokedGetAllCustomEmailForUserCount = 0
    public var invokedGetAllCustomEmailForUserParameters: (userId: String, Void)?
    public var invokedGetAllCustomEmailForUserParametersList = [(userId: String, Void)]()
    public var stubbedGetAllCustomEmailForUserResult: [CustomEmail]!

    public func getAllCustomEmailForUser(userId: String) async throws -> [CustomEmail] {
        invokedGetAllCustomEmailForUserfunction = true
        invokedGetAllCustomEmailForUserCount += 1
        invokedGetAllCustomEmailForUserParameters = (userId, ())
        invokedGetAllCustomEmailForUserParametersList.append((userId, ()))
        if let error = getAllCustomEmailForUserUserIdThrowableError2 {
            throw error
        }
        closureGetAllCustomEmailForUser()
        return stubbedGetAllCustomEmailForUserResult
    }
    // MARK: - addEmailToBreachMonitoring
    public var addEmailToBreachMonitoringUserIdEmailThrowableError3: Error?
    public var closureAddEmailToBreachMonitoring: () -> () = {}
    public var invokedAddEmailToBreachMonitoringfunction = false
    public var invokedAddEmailToBreachMonitoringCount = 0
    public var invokedAddEmailToBreachMonitoringParameters: (userId: String, email: String)?
    public var invokedAddEmailToBreachMonitoringParametersList = [(userId: String, email: String)]()
    public var stubbedAddEmailToBreachMonitoringResult: CustomEmail!

    public func addEmailToBreachMonitoring(userId: String, email: String) async throws -> CustomEmail {
        invokedAddEmailToBreachMonitoringfunction = true
        invokedAddEmailToBreachMonitoringCount += 1
        invokedAddEmailToBreachMonitoringParameters = (userId, email)
        invokedAddEmailToBreachMonitoringParametersList.append((userId, email))
        if let error = addEmailToBreachMonitoringUserIdEmailThrowableError3 {
            throw error
        }
        closureAddEmailToBreachMonitoring()
        return stubbedAddEmailToBreachMonitoringResult
    }
    // MARK: - verifyCustomEmail
    public var verifyCustomEmailUserIdEmailIdCodeThrowableError4: Error?
    public var closureVerifyCustomEmail: () -> () = {}
    public var invokedVerifyCustomEmailfunction = false
    public var invokedVerifyCustomEmailCount = 0
    public var invokedVerifyCustomEmailParameters: (userId: String, emailId: String, code: String)?
    public var invokedVerifyCustomEmailParametersList = [(userId: String, emailId: String, code: String)]()

    public func verifyCustomEmail(userId: String, emailId: String, code: String) async throws {
        invokedVerifyCustomEmailfunction = true
        invokedVerifyCustomEmailCount += 1
        invokedVerifyCustomEmailParameters = (userId, emailId, code)
        invokedVerifyCustomEmailParametersList.append((userId, emailId, code))
        if let error = verifyCustomEmailUserIdEmailIdCodeThrowableError4 {
            throw error
        }
        closureVerifyCustomEmail()
    }
    // MARK: - getAllBreachesForEmail
    public var getAllBreachesForEmailUserIdEmailIdThrowableError5: Error?
    public var closureGetAllBreachesForEmail: () -> () = {}
    public var invokedGetAllBreachesForEmailfunction = false
    public var invokedGetAllBreachesForEmailCount = 0
    public var invokedGetAllBreachesForEmailParameters: (userId: String, emailId: String)?
    public var invokedGetAllBreachesForEmailParametersList = [(userId: String, emailId: String)]()
    public var stubbedGetAllBreachesForEmailResult: EmailBreaches!

    public func getAllBreachesForEmail(userId: String, emailId: String) async throws -> EmailBreaches {
        invokedGetAllBreachesForEmailfunction = true
        invokedGetAllBreachesForEmailCount += 1
        invokedGetAllBreachesForEmailParameters = (userId, emailId)
        invokedGetAllBreachesForEmailParametersList.append((userId, emailId))
        if let error = getAllBreachesForEmailUserIdEmailIdThrowableError5 {
            throw error
        }
        closureGetAllBreachesForEmail()
        return stubbedGetAllBreachesForEmailResult
    }
    // MARK: - getAllBreachesForProtonAddress
    public var getAllBreachesForProtonAddressUserIdAddressIdThrowableError6: Error?
    public var closureGetAllBreachesForProtonAddress: () -> () = {}
    public var invokedGetAllBreachesForProtonAddressfunction = false
    public var invokedGetAllBreachesForProtonAddressCount = 0
    public var invokedGetAllBreachesForProtonAddressParameters: (userId: String, addressId: String)?
    public var invokedGetAllBreachesForProtonAddressParametersList = [(userId: String, addressId: String)]()
    public var stubbedGetAllBreachesForProtonAddressResult: EmailBreaches!

    public func getAllBreachesForProtonAddress(userId: String, addressId: String) async throws -> EmailBreaches {
        invokedGetAllBreachesForProtonAddressfunction = true
        invokedGetAllBreachesForProtonAddressCount += 1
        invokedGetAllBreachesForProtonAddressParameters = (userId, addressId)
        invokedGetAllBreachesForProtonAddressParametersList.append((userId, addressId))
        if let error = getAllBreachesForProtonAddressUserIdAddressIdThrowableError6 {
            throw error
        }
        closureGetAllBreachesForProtonAddress()
        return stubbedGetAllBreachesForProtonAddressResult
    }
    // MARK: - removeEmailFromBreachMonitoring
    public var removeEmailFromBreachMonitoringUserIdEmailIdThrowableError7: Error?
    public var closureRemoveEmailFromBreachMonitoring: () -> () = {}
    public var invokedRemoveEmailFromBreachMonitoringfunction = false
    public var invokedRemoveEmailFromBreachMonitoringCount = 0
    public var invokedRemoveEmailFromBreachMonitoringParameters: (userId: String, emailId: String)?
    public var invokedRemoveEmailFromBreachMonitoringParametersList = [(userId: String, emailId: String)]()

    public func removeEmailFromBreachMonitoring(userId: String, emailId: String) async throws {
        invokedRemoveEmailFromBreachMonitoringfunction = true
        invokedRemoveEmailFromBreachMonitoringCount += 1
        invokedRemoveEmailFromBreachMonitoringParameters = (userId, emailId)
        invokedRemoveEmailFromBreachMonitoringParametersList.append((userId, emailId))
        if let error = removeEmailFromBreachMonitoringUserIdEmailIdThrowableError7 {
            throw error
        }
        closureRemoveEmailFromBreachMonitoring()
    }
    // MARK: - getBreachesForAlias
    public var getBreachesForAliasUserIdSharedIdItemIdThrowableError8: Error?
    public var closureGetBreachesForAlias: () -> () = {}
    public var invokedGetBreachesForAliasfunction = false
    public var invokedGetBreachesForAliasCount = 0
    public var invokedGetBreachesForAliasParameters: (userId: String, sharedId: String, itemId: String)?
    public var invokedGetBreachesForAliasParametersList = [(userId: String, sharedId: String, itemId: String)]()
    public var stubbedGetBreachesForAliasResult: EmailBreaches!

    public func getBreachesForAlias(userId: String, sharedId: String, itemId: String) async throws -> EmailBreaches {
        invokedGetBreachesForAliasfunction = true
        invokedGetBreachesForAliasCount += 1
        invokedGetBreachesForAliasParameters = (userId, sharedId, itemId)
        invokedGetBreachesForAliasParametersList.append((userId, sharedId, itemId))
        if let error = getBreachesForAliasUserIdSharedIdItemIdThrowableError8 {
            throw error
        }
        closureGetBreachesForAlias()
        return stubbedGetBreachesForAliasResult
    }
    // MARK: - resendEmailVerification
    public var resendEmailVerificationUserIdEmailIdThrowableError9: Error?
    public var closureResendEmailVerification: () -> () = {}
    public var invokedResendEmailVerificationfunction = false
    public var invokedResendEmailVerificationCount = 0
    public var invokedResendEmailVerificationParameters: (userId: String, emailId: String)?
    public var invokedResendEmailVerificationParametersList = [(userId: String, emailId: String)]()

    public func resendEmailVerification(userId: String, emailId: String) async throws {
        invokedResendEmailVerificationfunction = true
        invokedResendEmailVerificationCount += 1
        invokedResendEmailVerificationParameters = (userId, emailId)
        invokedResendEmailVerificationParametersList.append((userId, emailId))
        if let error = resendEmailVerificationUserIdEmailIdThrowableError9 {
            throw error
        }
        closureResendEmailVerification()
    }
    // MARK: - markAliasAsResolved
    public var markAliasAsResolvedUserIdSharedIdItemIdThrowableError10: Error?
    public var closureMarkAliasAsResolved: () -> () = {}
    public var invokedMarkAliasAsResolvedfunction = false
    public var invokedMarkAliasAsResolvedCount = 0
    public var invokedMarkAliasAsResolvedParameters: (userId: String, sharedId: String, itemId: String)?
    public var invokedMarkAliasAsResolvedParametersList = [(userId: String, sharedId: String, itemId: String)]()

    public func markAliasAsResolved(userId: String, sharedId: String, itemId: String) async throws {
        invokedMarkAliasAsResolvedfunction = true
        invokedMarkAliasAsResolvedCount += 1
        invokedMarkAliasAsResolvedParameters = (userId, sharedId, itemId)
        invokedMarkAliasAsResolvedParametersList.append((userId, sharedId, itemId))
        if let error = markAliasAsResolvedUserIdSharedIdItemIdThrowableError10 {
            throw error
        }
        closureMarkAliasAsResolved()
    }
    // MARK: - markProtonAddressAsResolved
    public var markProtonAddressAsResolvedUserIdAddressThrowableError11: Error?
    public var closureMarkProtonAddressAsResolved: () -> () = {}
    public var invokedMarkProtonAddressAsResolvedfunction = false
    public var invokedMarkProtonAddressAsResolvedCount = 0
    public var invokedMarkProtonAddressAsResolvedParameters: (userId: String, address: ProtonAddress)?
    public var invokedMarkProtonAddressAsResolvedParametersList = [(userId: String, address: ProtonAddress)]()

    public func markProtonAddressAsResolved(userId: String, address: ProtonAddress) async throws {
        invokedMarkProtonAddressAsResolvedfunction = true
        invokedMarkProtonAddressAsResolvedCount += 1
        invokedMarkProtonAddressAsResolvedParameters = (userId, address)
        invokedMarkProtonAddressAsResolvedParametersList.append((userId, address))
        if let error = markProtonAddressAsResolvedUserIdAddressThrowableError11 {
            throw error
        }
        closureMarkProtonAddressAsResolved()
    }
    // MARK: - markCustomEmailAsResolved
    public var markCustomEmailAsResolvedUserIdEmailThrowableError12: Error?
    public var closureMarkCustomEmailAsResolved: () -> () = {}
    public var invokedMarkCustomEmailAsResolvedfunction = false
    public var invokedMarkCustomEmailAsResolvedCount = 0
    public var invokedMarkCustomEmailAsResolvedParameters: (userId: String, email: CustomEmail)?
    public var invokedMarkCustomEmailAsResolvedParametersList = [(userId: String, email: CustomEmail)]()
    public var stubbedMarkCustomEmailAsResolvedResult: CustomEmail!

    public func markCustomEmailAsResolved(userId: String, email: CustomEmail) async throws -> CustomEmail {
        invokedMarkCustomEmailAsResolvedfunction = true
        invokedMarkCustomEmailAsResolvedCount += 1
        invokedMarkCustomEmailAsResolvedParameters = (userId, email)
        invokedMarkCustomEmailAsResolvedParametersList.append((userId, email))
        if let error = markCustomEmailAsResolvedUserIdEmailThrowableError12 {
            throw error
        }
        closureMarkCustomEmailAsResolved()
        return stubbedMarkCustomEmailAsResolvedResult
    }
    // MARK: - toggleMonitoringForUserIdAddressShouldMonitor
    public var toggleMonitoringForUserIdAddressShouldMonitorThrowableError13: Error?
    public var closureToggleMonitoringForUserIdAddressShouldMonitorAsync13: () -> () = {}
    public var invokedToggleMonitoringForUserIdAddressShouldMonitorAsync13 = false
    public var invokedToggleMonitoringForUserIdAddressShouldMonitorAsyncCount13 = 0
    public var invokedToggleMonitoringForUserIdAddressShouldMonitorAsyncParameters13: (userId: String, address: ProtonAddress, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForUserIdAddressShouldMonitorAsyncParametersList13 = [(userId: String, address: ProtonAddress, shouldMonitor: Bool)]()

    public func toggleMonitoringFor(userId: String, address: ProtonAddress, shouldMonitor: Bool) async throws {
        invokedToggleMonitoringForUserIdAddressShouldMonitorAsync13 = true
        invokedToggleMonitoringForUserIdAddressShouldMonitorAsyncCount13 += 1
        invokedToggleMonitoringForUserIdAddressShouldMonitorAsyncParameters13 = (userId, address, shouldMonitor)
        invokedToggleMonitoringForUserIdAddressShouldMonitorAsyncParametersList13.append((userId, address, shouldMonitor))
        if let error = toggleMonitoringForUserIdAddressShouldMonitorThrowableError13 {
            throw error
        }
        closureToggleMonitoringForUserIdAddressShouldMonitorAsync13()
    }
    // MARK: - toggleMonitoringForUserIdEmailShouldMonitor
    public var toggleMonitoringForUserIdEmailShouldMonitorThrowableError14: Error?
    public var closureToggleMonitoringForUserIdEmailShouldMonitorAsync14: () -> () = {}
    public var invokedToggleMonitoringForUserIdEmailShouldMonitorAsync14 = false
    public var invokedToggleMonitoringForUserIdEmailShouldMonitorAsyncCount14 = 0
    public var invokedToggleMonitoringForUserIdEmailShouldMonitorAsyncParameters14: (userId: String, email: CustomEmail, shouldMonitor: Bool)?
    public var invokedToggleMonitoringForUserIdEmailShouldMonitorAsyncParametersList14 = [(userId: String, email: CustomEmail, shouldMonitor: Bool)]()
    public var stubbedToggleMonitoringForUserIdEmailShouldMonitorAsyncResult14: CustomEmail!

    public func toggleMonitoringFor(userId: String, email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail {
        invokedToggleMonitoringForUserIdEmailShouldMonitorAsync14 = true
        invokedToggleMonitoringForUserIdEmailShouldMonitorAsyncCount14 += 1
        invokedToggleMonitoringForUserIdEmailShouldMonitorAsyncParameters14 = (userId, email, shouldMonitor)
        invokedToggleMonitoringForUserIdEmailShouldMonitorAsyncParametersList14.append((userId, email, shouldMonitor))
        if let error = toggleMonitoringForUserIdEmailShouldMonitorThrowableError14 {
            throw error
        }
        closureToggleMonitoringForUserIdEmailShouldMonitorAsync14()
        return stubbedToggleMonitoringForUserIdEmailShouldMonitorAsyncResult14
    }
}
