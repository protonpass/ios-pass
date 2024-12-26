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
import Core
import Entities

public final class AccessRepositoryProtocolMock: @unchecked Sendable, AccessRepositoryProtocol {

    public init() {}

    // MARK: - access
    public var invokedAccessSetter = false
    public var invokedAccessSetterCount = 0
    public var invokedAccess: CurrentValueSubject<UserAccess?, Never>?
    public var invokedAccessList = [CurrentValueSubject<UserAccess?, Never>?]()
    public var invokedAccessGetter = false
    public var invokedAccessGetterCount = 0
    public var stubbedAccess: CurrentValueSubject<UserAccess?, Never>!
    public var access: CurrentValueSubject<UserAccess?, Never> {
        set {
            invokedAccessSetter = true
            invokedAccessSetterCount += 1
            invokedAccess = newValue
            invokedAccessList.append(newValue)
        } get {
            invokedAccessGetter = true
            invokedAccessGetterCount += 1
            return stubbedAccess
        }
    }
    // MARK: - accesses
    public var invokedAccessesSetter = false
    public var invokedAccessesSetterCount = 0
    public var invokedAccesses: CurrentValueSubject<[UserAccess], Never>?
    public var invokedAccessesList = [CurrentValueSubject<[UserAccess], Never>?]()
    public var invokedAccessesGetter = false
    public var invokedAccessesGetterCount = 0
    public var stubbedAccesses: CurrentValueSubject<[UserAccess], Never>!
    public var accesses: CurrentValueSubject<[UserAccess], Never> {
        set {
            invokedAccessesSetter = true
            invokedAccessesSetterCount += 1
            invokedAccesses = newValue
            invokedAccessesList.append(newValue)
        } get {
            invokedAccessesGetter = true
            invokedAccessesGetterCount += 1
            return stubbedAccesses
        }
    }
    // MARK: - didUpdateToNewPlan
    public var invokedDidUpdateToNewPlanSetter = false
    public var invokedDidUpdateToNewPlanSetterCount = 0
    public var invokedDidUpdateToNewPlan: PassthroughSubject<Void, Never>?
    public var invokedDidUpdateToNewPlanList = [PassthroughSubject<Void, Never>?]()
    public var invokedDidUpdateToNewPlanGetter = false
    public var invokedDidUpdateToNewPlanGetterCount = 0
    public var stubbedDidUpdateToNewPlan: PassthroughSubject<Void, Never>!
    public var didUpdateToNewPlan: PassthroughSubject<Void, Never> {
        set {
            invokedDidUpdateToNewPlanSetter = true
            invokedDidUpdateToNewPlanSetterCount += 1
            invokedDidUpdateToNewPlan = newValue
            invokedDidUpdateToNewPlanList.append(newValue)
        } get {
            invokedDidUpdateToNewPlanGetter = true
            invokedDidUpdateToNewPlanGetterCount += 1
            return stubbedDidUpdateToNewPlan
        }
    }
    // MARK: - getAccess
    public var getAccessUserIdThrowableError1: Error?
    public var closureGetAccess: () -> () = {}
    public var invokedGetAccessfunction = false
    public var invokedGetAccessCount = 0
    public var invokedGetAccessParameters: (userId: String?, Void)?
    public var invokedGetAccessParametersList = [(userId: String?, Void)]()
    public var stubbedGetAccessResult: UserAccess!

    public func getAccess(userId: String?) async throws -> UserAccess {
        invokedGetAccessfunction = true
        invokedGetAccessCount += 1
        invokedGetAccessParameters = (userId, ())
        invokedGetAccessParametersList.append((userId, ()))
        if let error = getAccessUserIdThrowableError1 {
            throw error
        }
        closureGetAccess()
        return stubbedGetAccessResult
    }
    // MARK: - refreshAccess
    public var refreshAccessUserIdThrowableError2: Error?
    public var closureRefreshAccess: () -> () = {}
    public var invokedRefreshAccessfunction = false
    public var invokedRefreshAccessCount = 0
    public var invokedRefreshAccessParameters: (userId: String?, Void)?
    public var invokedRefreshAccessParametersList = [(userId: String?, Void)]()
    public var stubbedRefreshAccessResult: UserAccess!

    public func refreshAccess(userId: String?) async throws -> UserAccess {
        invokedRefreshAccessfunction = true
        invokedRefreshAccessCount += 1
        invokedRefreshAccessParameters = (userId, ())
        invokedRefreshAccessParametersList.append((userId, ()))
        if let error = refreshAccessUserIdThrowableError2 {
            throw error
        }
        closureRefreshAccess()
        return stubbedRefreshAccessResult
    }
    // MARK: - loadAccesses
    public var loadAccessesThrowableError3: Error?
    public var closureLoadAccesses: () -> () = {}
    public var invokedLoadAccessesfunction = false
    public var invokedLoadAccessesCount = 0

    public func loadAccesses() async throws {
        invokedLoadAccessesfunction = true
        invokedLoadAccessesCount += 1
        if let error = loadAccessesThrowableError3 {
            throw error
        }
        closureLoadAccesses()
    }
    // MARK: - updateProtonAddressesMonitor
    public var updateProtonAddressesMonitorUserIdMonitoredThrowableError4: Error?
    public var closureUpdateProtonAddressesMonitor: () -> () = {}
    public var invokedUpdateProtonAddressesMonitorfunction = false
    public var invokedUpdateProtonAddressesMonitorCount = 0
    public var invokedUpdateProtonAddressesMonitorParameters: (userId: String?, monitored: Bool)?
    public var invokedUpdateProtonAddressesMonitorParametersList = [(userId: String?, monitored: Bool)]()

    public func updateProtonAddressesMonitor(userId: String?, monitored: Bool) async throws {
        invokedUpdateProtonAddressesMonitorfunction = true
        invokedUpdateProtonAddressesMonitorCount += 1
        invokedUpdateProtonAddressesMonitorParameters = (userId, monitored)
        invokedUpdateProtonAddressesMonitorParametersList.append((userId, monitored))
        if let error = updateProtonAddressesMonitorUserIdMonitoredThrowableError4 {
            throw error
        }
        closureUpdateProtonAddressesMonitor()
    }
    // MARK: - updateAliasesMonitor
    public var updateAliasesMonitorUserIdMonitoredThrowableError5: Error?
    public var closureUpdateAliasesMonitor: () -> () = {}
    public var invokedUpdateAliasesMonitorfunction = false
    public var invokedUpdateAliasesMonitorCount = 0
    public var invokedUpdateAliasesMonitorParameters: (userId: String?, monitored: Bool)?
    public var invokedUpdateAliasesMonitorParametersList = [(userId: String?, monitored: Bool)]()

    public func updateAliasesMonitor(userId: String?, monitored: Bool) async throws {
        invokedUpdateAliasesMonitorfunction = true
        invokedUpdateAliasesMonitorCount += 1
        invokedUpdateAliasesMonitorParameters = (userId, monitored)
        invokedUpdateAliasesMonitorParametersList.append((userId, monitored))
        if let error = updateAliasesMonitorUserIdMonitoredThrowableError5 {
            throw error
        }
        closureUpdateAliasesMonitor()
    }
    // MARK: - getPassUserInformation
    public var getPassUserInformationUserIdThrowableError6: Error?
    public var closureGetPassUserInformation: () -> () = {}
    public var invokedGetPassUserInformationfunction = false
    public var invokedGetPassUserInformationCount = 0
    public var invokedGetPassUserInformationParameters: (userId: String, Void)?
    public var invokedGetPassUserInformationParametersList = [(userId: String, Void)]()
    public var stubbedGetPassUserInformationResult: PassUserInformations!

    public func getPassUserInformation(userId: String) async throws -> PassUserInformations {
        invokedGetPassUserInformationfunction = true
        invokedGetPassUserInformationCount += 1
        invokedGetPassUserInformationParameters = (userId, ())
        invokedGetPassUserInformationParametersList.append((userId, ()))
        if let error = getPassUserInformationUserIdThrowableError6 {
            throw error
        }
        closureGetPassUserInformation()
        return stubbedGetPassUserInformationResult
    }
}
