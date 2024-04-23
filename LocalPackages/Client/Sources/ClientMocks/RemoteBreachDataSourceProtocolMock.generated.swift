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
    public var getAllBreachesForEmailEmailIdThrowableError5: Error?
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
        if let error = getAllBreachesForEmailEmailIdThrowableError5 {
            throw error
        }
        closureGetAllBreachesForEmail()
        return stubbedGetAllBreachesForEmailResult
    }
    // MARK: - removeEmailFromBreachMonitoring
    public var removeEmailFromBreachMonitoringEmailIdThrowableError6: Error?
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
        if let error = removeEmailFromBreachMonitoringEmailIdThrowableError6 {
            throw error
        }
        closureRemoveEmailFromBreachMonitoring()
    }
    // MARK: - getBreachesForAlias
    public var getBreachesForAliasSharedIdItemIdThrowableError7: Error?
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
        if let error = getBreachesForAliasSharedIdItemIdThrowableError7 {
            throw error
        }
        closureGetBreachesForAlias()
        return stubbedGetBreachesForAliasResult
    }
    // MARK: - resendEmailVerification
    public var resendEmailVerificationEmailIdThrowableError8: Error?
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
        if let error = resendEmailVerificationEmailIdThrowableError8 {
            throw error
        }
        closureResendEmailVerification()
    }
}
