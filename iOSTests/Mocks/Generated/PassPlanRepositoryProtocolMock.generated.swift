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

@testable import Proton_Pass
import Core

final class PassPlanRepositoryProtocolMock: @unchecked Sendable, PassPlanRepositoryProtocol {
    // MARK: - localDatasource
    var invokedLocalDatasourceSetter = false
    var invokedLocalDatasourceSetterCount = 0
    var invokedLocalDatasource: LocalPassPlanDatasourceProtocol?
    var invokedLocalDatasourceList = [LocalPassPlanDatasourceProtocol?]()
    var invokedLocalDatasourceGetter = false
    var invokedLocalDatasourceGetterCount = 0
    var stubbedLocalDatasource: LocalPassPlanDatasourceProtocol!
    var localDatasource: LocalPassPlanDatasourceProtocol {
        set {
            invokedLocalDatasourceSetter = true
            invokedLocalDatasourceSetterCount += 1
            invokedLocalDatasource = newValue
            invokedLocalDatasourceList.append(newValue)
        } get {
            invokedLocalDatasourceGetter = true
            invokedLocalDatasourceGetterCount += 1
            return stubbedLocalDatasource
        }
    }
    // MARK: - remoteDatasource
    var invokedRemoteDatasourceSetter = false
    var invokedRemoteDatasourceSetterCount = 0
    var invokedRemoteDatasource: RemotePassPlanDatasourceProtocol?
    var invokedRemoteDatasourceList = [RemotePassPlanDatasourceProtocol?]()
    var invokedRemoteDatasourceGetter = false
    var invokedRemoteDatasourceGetterCount = 0
    var stubbedRemoteDatasource: RemotePassPlanDatasourceProtocol!
    var remoteDatasource: RemotePassPlanDatasourceProtocol {
        set {
            invokedRemoteDatasourceSetter = true
            invokedRemoteDatasourceSetterCount += 1
            invokedRemoteDatasource = newValue
            invokedRemoteDatasourceList.append(newValue)
        } get {
            invokedRemoteDatasourceGetter = true
            invokedRemoteDatasourceGetterCount += 1
            return stubbedRemoteDatasource
        }
    }
    // MARK: - userId
    var invokedUserIdSetter = false
    var invokedUserIdSetterCount = 0
    var invokedUserId: String?
    var invokedUserIdList = [String?]()
    var invokedUserIdGetter = false
    var invokedUserIdGetterCount = 0
    var stubbedUserId: String!
    var userId: String {
        set {
            invokedUserIdSetter = true
            invokedUserIdSetterCount += 1
            invokedUserId = newValue
            invokedUserIdList.append(newValue)
        } get {
            invokedUserIdGetter = true
            invokedUserIdGetterCount += 1
            return stubbedUserId
        }
    }
    // MARK: - logger
    var invokedLoggerSetter = false
    var invokedLoggerSetterCount = 0
    var invokedLogger: Logger?
    var invokedLoggerList = [Logger?]()
    var invokedLoggerGetter = false
    var invokedLoggerGetterCount = 0
    var stubbedLogger: Logger!
    var logger: Logger {
        set {
            invokedLoggerSetter = true
            invokedLoggerSetterCount += 1
            invokedLogger = newValue
            invokedLoggerList.append(newValue)
        } get {
            invokedLoggerGetter = true
            invokedLoggerGetterCount += 1
            return stubbedLogger
        }
    }
    // MARK: - delegate
    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    var invokedDelegate: PassPlanRepositoryDelegate?
    var invokedDelegateList = [PassPlanRepositoryDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    var stubbedDelegate: PassPlanRepositoryDelegate!
    var delegate: PassPlanRepositoryDelegate? {
        set {
            invokedDelegateSetter = true
            invokedDelegateSetterCount += 1
            invokedDelegate = newValue
            invokedDelegateList.append(newValue)
        } get {
            invokedDelegateGetter = true
            invokedDelegateGetterCount += 1
            return stubbedDelegate
        }
    }
    // MARK: - getPlan
    var getPlanThrowableError: Error?
    var closureGetPlan: () -> () = {}
    var invokedGetPlan = false
    var invokedGetPlanCount = 0
    var stubbedGetPlanResult: PassPlan!

    func getPlan() async throws -> PassPlan {
        invokedGetPlan = true
        invokedGetPlanCount += 1
        if let error = getPlanThrowableError {
            throw error
        }
        closureGetPlan()
        return stubbedGetPlanResult
    }
    // MARK: - refreshPlan
    var refreshPlanThrowableError: Error?
    var closureRefreshPlan: () -> () = {}
    var invokedRefreshPlan = false
    var invokedRefreshPlanCount = 0
    var stubbedRefreshPlanResult: PassPlan!

    func refreshPlan() async throws -> PassPlan {
        invokedRefreshPlan = true
        invokedRefreshPlanCount += 1
        if let error = refreshPlanThrowableError {
            throw error
        }
        closureRefreshPlan()
        return stubbedRefreshPlanResult
    }
}
