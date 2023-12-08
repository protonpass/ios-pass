// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
    public var stubbedGetAccessResult: Access!

    public func getAccess() async throws -> Access {
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
    public var stubbedRefreshAccessResult: Access!

    public func refreshAccess() async throws -> Access {
        invokedRefreshAccessfunction = true
        invokedRefreshAccessCount += 1
        if let error = refreshAccessThrowableError3 {
            throw error
        }
        closureRefreshAccess()
        return stubbedRefreshAccessResult
    }
}
