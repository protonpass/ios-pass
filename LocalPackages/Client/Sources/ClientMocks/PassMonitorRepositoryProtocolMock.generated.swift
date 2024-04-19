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
import CryptoKit
import Entities
import Foundation
import PassRustCore

public final class PassMonitorRepositoryProtocolMock: @unchecked Sendable, PassMonitorRepositoryProtocol {

    public init() {}

    // MARK: - state
    public var invokedStateSetter = false
    public var invokedStateSetterCount = 0
    public var invokedState: CurrentValueSubject<MonitorState, Never>?
    public var invokedStateList = [CurrentValueSubject<MonitorState, Never>?]()
    public var invokedStateGetter = false
    public var invokedStateGetterCount = 0
    public var stubbedState: CurrentValueSubject<MonitorState, Never>!
    public var state: CurrentValueSubject<MonitorState, Never> {
        set {
            invokedStateSetter = true
            invokedStateSetterCount += 1
            invokedState = newValue
            invokedStateList.append(newValue)
        } get {
            invokedStateGetter = true
            invokedStateGetterCount += 1
            return stubbedState
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
    // MARK: - updateState
    public var closureUpdateState: () -> () = {}
    public var invokedUpdateStatefunction = false
    public var invokedUpdateStateCount = 0
    public var invokedUpdateStateParameters: (newValue: MonitorState, Void)?
    public var invokedUpdateStateParametersList = [(newValue: MonitorState, Void)]()

    public func updateState(_ newValue: MonitorState) async {
        invokedUpdateStatefunction = true
        invokedUpdateStateCount += 1
        invokedUpdateStateParameters = (newValue, ())
        invokedUpdateStateParametersList.append((newValue, ()))
        closureUpdateState()
    }
}
