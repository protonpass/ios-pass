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
import Entities
import Foundation
import PassRustCore

public final class SecurityCenterRepositoryProtocolMock: @unchecked Sendable, SecurityCenterRepositoryProtocol {

    public init() {}

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
    // MARK: - hasBreachedItems
    public var invokedHasBreachedItemsSetter = false
    public var invokedHasBreachedItemsSetterCount = 0
    public var invokedHasBreachedItems: CurrentValueSubject<Bool, Never>?
    public var invokedHasBreachedItemsList = [CurrentValueSubject<Bool, Never>?]()
    public var invokedHasBreachedItemsGetter = false
    public var invokedHasBreachedItemsGetterCount = 0
    public var stubbedHasBreachedItems: CurrentValueSubject<Bool, Never>!
    public var hasBreachedItems: CurrentValueSubject<Bool, Never> {
        set {
            invokedHasBreachedItemsSetter = true
            invokedHasBreachedItemsSetterCount += 1
            invokedHasBreachedItems = newValue
            invokedHasBreachedItemsList.append(newValue)
        } get {
            invokedHasBreachedItemsGetter = true
            invokedHasBreachedItemsGetterCount += 1
            return stubbedHasBreachedItems
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
}
