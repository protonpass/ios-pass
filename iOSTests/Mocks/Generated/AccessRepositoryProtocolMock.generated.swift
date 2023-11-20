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
// swiftlint:disable all

@testable import Client
import Combine
import Core
import Entities

final class AccessRepositoryProtocolMock: @unchecked Sendable, AccessRepositoryProtocol {
    // MARK: - didUpdateToNewPlan
    var invokedDidUpdateToNewPlanSetter = false
    var invokedDidUpdateToNewPlanSetterCount = 0
    var invokedDidUpdateToNewPlan: PassthroughSubject<Void, Never>?
    var invokedDidUpdateToNewPlanList = [PassthroughSubject<Void, Never>?]()
    var invokedDidUpdateToNewPlanGetter = false
    var invokedDidUpdateToNewPlanGetterCount = 0
    var stubbedDidUpdateToNewPlan: PassthroughSubject<Void, Never>!
    var didUpdateToNewPlan: PassthroughSubject<Void, Never> {
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
    var getAccessThrowableError: Error?
    var closureGetAccess: () -> () = {}
    var invokedGetAccess = false
    var invokedGetAccessCount = 0
    var stubbedGetAccessResult: Access!

    func getAccess() async throws -> Access {
        invokedGetAccess = true
        invokedGetAccessCount += 1
        if let error = getAccessThrowableError {
            throw error
        }
        closureGetAccess()
        return stubbedGetAccessResult
    }
    // MARK: - getPlan
    var getPlanThrowableError: Error?
    var closureGetPlan: () -> () = {}
    var invokedGetPlan = false
    var invokedGetPlanCount = 0
    var stubbedGetPlanResult: Plan!

    func getPlan() async throws -> Plan {
        invokedGetPlan = true
        invokedGetPlanCount += 1
        if let error = getPlanThrowableError {
            throw error
        }
        closureGetPlan()
        return stubbedGetPlanResult
    }
    // MARK: - refreshAccess
    var refreshAccessThrowableError: Error?
    var closureRefreshAccess: () -> () = {}
    var invokedRefreshAccess = false
    var invokedRefreshAccessCount = 0
    var stubbedRefreshAccessResult: Access!

    func refreshAccess() async throws -> Access {
        invokedRefreshAccess = true
        invokedRefreshAccessCount += 1
        if let error = refreshAccessThrowableError {
            throw error
        }
        closureRefreshAccess()
        return stubbedRefreshAccessResult
    }
}
