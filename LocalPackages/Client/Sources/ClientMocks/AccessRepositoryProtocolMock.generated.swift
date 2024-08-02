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
    public var getAccessThrowableError1: Error?
    public var closureGetAccess: () -> () = {}
    public var invokedGetAccessfunction = false
    public var invokedGetAccessCount = 0
    public var stubbedGetAccessResult: UserAccess!

    public func getAccess() async throws -> UserAccess {
        invokedGetAccessfunction = true
        invokedGetAccessCount += 1
        if let error = getAccessThrowableError1 {
            throw error
        }
        closureGetAccess()
        return stubbedGetAccessResult
    }
    // MARK: - getPlan
    public var getPlanThrowableError2: Error?
    public var closureGetPlan: () -> () = {}
    public var invokedGetPlanfunction = false
    public var invokedGetPlanCount = 0
    public var stubbedGetPlanResult: Plan!

    public func getPlan() async throws -> Plan {
        invokedGetPlanfunction = true
        invokedGetPlanCount += 1
        if let error = getPlanThrowableError2 {
            throw error
        }
        closureGetPlan()
        return stubbedGetPlanResult
    }
    // MARK: - refreshAccess
    public var refreshAccessThrowableError3: Error?
    public var closureRefreshAccess: () -> () = {}
    public var invokedRefreshAccessfunction = false
    public var invokedRefreshAccessCount = 0
    public var stubbedRefreshAccessResult: UserAccess!

    public func refreshAccess() async throws -> UserAccess {
        invokedRefreshAccessfunction = true
        invokedRefreshAccessCount += 1
        if let error = refreshAccessThrowableError3 {
            throw error
        }
        closureRefreshAccess()
        return stubbedRefreshAccessResult
    }
    // MARK: - loadAccesses
    public var loadAccessesThrowableError4: Error?
    public var closureLoadAccesses: () -> () = {}
    public var invokedLoadAccessesfunction = false
    public var invokedLoadAccessesCount = 0

    public func loadAccesses() async throws {
        invokedLoadAccessesfunction = true
        invokedLoadAccessesCount += 1
        if let error = loadAccessesThrowableError4 {
            throw error
        }
        closureLoadAccesses()
    }
    // MARK: - updateProtonAddressesMonitor
    public var updateProtonAddressesMonitorThrowableError5: Error?
    public var closureUpdateProtonAddressesMonitor: () -> () = {}
    public var invokedUpdateProtonAddressesMonitorfunction = false
    public var invokedUpdateProtonAddressesMonitorCount = 0
    public var invokedUpdateProtonAddressesMonitorParameters: (monitored: Bool, Void)?
    public var invokedUpdateProtonAddressesMonitorParametersList = [(monitored: Bool, Void)]()

    public func updateProtonAddressesMonitor(_ monitored: Bool) async throws {
        invokedUpdateProtonAddressesMonitorfunction = true
        invokedUpdateProtonAddressesMonitorCount += 1
        invokedUpdateProtonAddressesMonitorParameters = (monitored, ())
        invokedUpdateProtonAddressesMonitorParametersList.append((monitored, ()))
        if let error = updateProtonAddressesMonitorThrowableError5 {
            throw error
        }
        closureUpdateProtonAddressesMonitor()
    }
    // MARK: - updateAliasesMonitor
    public var updateAliasesMonitorThrowableError6: Error?
    public var closureUpdateAliasesMonitor: () -> () = {}
    public var invokedUpdateAliasesMonitorfunction = false
    public var invokedUpdateAliasesMonitorCount = 0
    public var invokedUpdateAliasesMonitorParameters: (monitored: Bool, Void)?
    public var invokedUpdateAliasesMonitorParametersList = [(monitored: Bool, Void)]()

    public func updateAliasesMonitor(_ monitored: Bool) async throws {
        invokedUpdateAliasesMonitorfunction = true
        invokedUpdateAliasesMonitorCount += 1
        invokedUpdateAliasesMonitorParameters = (monitored, ())
        invokedUpdateAliasesMonitorParametersList.append((monitored, ()))
        if let error = updateAliasesMonitorThrowableError6 {
            throw error
        }
        closureUpdateAliasesMonitor()
    }
}
