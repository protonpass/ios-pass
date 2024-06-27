// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
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
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking

public final class UserManagerProtocolMock: @unchecked Sendable, UserManagerProtocol {

    public init() {}

    // MARK: - currentActiveUser
    public var invokedCurrentActiveUserSetter = false
    public var invokedCurrentActiveUserSetterCount = 0
    public var invokedCurrentActiveUser: CurrentValueSubject<UserData?, Never>?
    public var invokedCurrentActiveUserList = [CurrentValueSubject<UserData?, Never>?]()
    public var invokedCurrentActiveUserGetter = false
    public var invokedCurrentActiveUserGetterCount = 0
    public var stubbedCurrentActiveUser: CurrentValueSubject<UserData?, Never>!
    public var currentActiveUser: CurrentValueSubject<UserData?, Never> {
        set {
            invokedCurrentActiveUserSetter = true
            invokedCurrentActiveUserSetterCount += 1
            invokedCurrentActiveUser = newValue
            invokedCurrentActiveUserList.append(newValue)
        } get {
            invokedCurrentActiveUserGetter = true
            invokedCurrentActiveUserGetterCount += 1
            return stubbedCurrentActiveUser
        }
    }
    // MARK: - setUp
    public var setUpThrowableError1: Error?
    public var closureSetUp: () -> () = {}
    public var invokedSetUpfunction = false
    public var invokedSetUpCount = 0

    public func setUp() async throws {
        invokedSetUpfunction = true
        invokedSetUpCount += 1
        if let error = setUpThrowableError1 {
            throw error
        }
        closureSetUp()
    }
    // MARK: - getActiveUserData
    public var getActiveUserDataThrowableError2: Error?
    public var closureGetActiveUserData: () -> () = {}
    public var invokedGetActiveUserDatafunction = false
    public var invokedGetActiveUserDataCount = 0
    public var stubbedGetActiveUserDataResult: UserData?

    public func getActiveUserData() async throws -> UserData? {
        invokedGetActiveUserDatafunction = true
        invokedGetActiveUserDataCount += 1
        if let error = getActiveUserDataThrowableError2 {
            throw error
        }
        closureGetActiveUserData()
        return stubbedGetActiveUserDataResult
    }
    // MARK: - getUnwrappedActiveUserData
    public var getUnwrappedActiveUserDataThrowableError3: Error?
    public var closureGetUnwrappedActiveUserData: () -> () = {}
    public var invokedGetUnwrappedActiveUserDatafunction = false
    public var invokedGetUnwrappedActiveUserDataCount = 0
    public var stubbedGetUnwrappedActiveUserDataResult: UserData!

    public func getUnwrappedActiveUserData() async throws -> UserData {
        invokedGetUnwrappedActiveUserDatafunction = true
        invokedGetUnwrappedActiveUserDataCount += 1
        if let error = getUnwrappedActiveUserDataThrowableError3 {
            throw error
        }
        closureGetUnwrappedActiveUserData()
        return stubbedGetUnwrappedActiveUserDataResult
    }
    // MARK: - addAndMarkAsActive
    public var addAndMarkAsActiveUserDataThrowableError4: Error?
    public var closureAddAndMarkAsActive: () -> () = {}
    public var invokedAddAndMarkAsActivefunction = false
    public var invokedAddAndMarkAsActiveCount = 0
    public var invokedAddAndMarkAsActiveParameters: (userData: UserData, Void)?
    public var invokedAddAndMarkAsActiveParametersList = [(userData: UserData, Void)]()

    public func addAndMarkAsActive(userData: UserData) async throws {
        invokedAddAndMarkAsActivefunction = true
        invokedAddAndMarkAsActiveCount += 1
        invokedAddAndMarkAsActiveParameters = (userData, ())
        invokedAddAndMarkAsActiveParametersList.append((userData, ()))
        if let error = addAndMarkAsActiveUserDataThrowableError4 {
            throw error
        }
        closureAddAndMarkAsActive()
    }
    // MARK: - update
    public var updateUserDataThrowableError5: Error?
    public var closureUpdate: () -> () = {}
    public var invokedUpdatefunction = false
    public var invokedUpdateCount = 0
    public var invokedUpdateParameters: (userData: UserData, Void)?
    public var invokedUpdateParametersList = [(userData: UserData, Void)]()

    public func update(userData: UserData) async throws {
        invokedUpdatefunction = true
        invokedUpdateCount += 1
        invokedUpdateParameters = (userData, ())
        invokedUpdateParametersList.append((userData, ()))
        if let error = updateUserDataThrowableError5 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - switchActiveUser
    public var switchActiveUserWithThrowableError6: Error?
    public var closureSwitchActiveUser: () -> () = {}
    public var invokedSwitchActiveUserfunction = false
    public var invokedSwitchActiveUserCount = 0
    public var invokedSwitchActiveUserParameters: (userId: String, Void)?
    public var invokedSwitchActiveUserParametersList = [(userId: String, Void)]()

    public func switchActiveUser(with userId: String) async throws {
        invokedSwitchActiveUserfunction = true
        invokedSwitchActiveUserCount += 1
        invokedSwitchActiveUserParameters = (userId, ())
        invokedSwitchActiveUserParametersList.append((userId, ()))
        if let error = switchActiveUserWithThrowableError6 {
            throw error
        }
        closureSwitchActiveUser()
    }
    // MARK: - getAllUser
    public var getAllUserThrowableError7: Error?
    public var closureGetAllUser: () -> () = {}
    public var invokedGetAllUserfunction = false
    public var invokedGetAllUserCount = 0
    public var stubbedGetAllUserResult: [UserData]!

    public func getAllUser() async throws -> [UserData] {
        invokedGetAllUserfunction = true
        invokedGetAllUserCount += 1
        if let error = getAllUserThrowableError7 {
            throw error
        }
        closureGetAllUser()
        return stubbedGetAllUserResult
    }
    // MARK: - remove
    public var removeUserIdThrowableError8: Error?
    public var closureRemove: () -> () = {}
    public var invokedRemovefunction = false
    public var invokedRemoveCount = 0
    public var invokedRemoveParameters: (userId: String, Void)?
    public var invokedRemoveParametersList = [(userId: String, Void)]()

    public func remove(userId: String) async throws {
        invokedRemovefunction = true
        invokedRemoveCount += 1
        invokedRemoveParameters = (userId, ())
        invokedRemoveParametersList.append((userId, ()))
        if let error = removeUserIdThrowableError8 {
            throw error
        }
        closureRemove()
    }
    // MARK: - getActiveUserId
    public var getActiveUserIdThrowableError9: Error?
    public var closureGetActiveUserId: () -> () = {}
    public var invokedGetActiveUserIdfunction = false
    public var invokedGetActiveUserIdCount = 0
    public var stubbedGetActiveUserIdResult: String!

    public func getActiveUserId() async throws -> String {
        invokedGetActiveUserIdfunction = true
        invokedGetActiveUserIdCount += 1
        if let error = getActiveUserIdThrowableError9 {
            throw error
        }
        closureGetActiveUserId()
        return stubbedGetActiveUserIdResult
    }
    // MARK: - setUserData
    public var closureSetUserData: () -> () = {}
    public var invokedSetUserDatafunction = false
    public var invokedSetUserDataCount = 0
    public var invokedSetUserDataParameters: (userData: UserData, Void)?
    public var invokedSetUserDataParametersList = [(userData: UserData, Void)]()

    public func setUserData(_ userData: UserData) {
        invokedSetUserDatafunction = true
        invokedSetUserDataCount += 1
        invokedSetUserDataParameters = (userData, ())
        invokedSetUserDataParametersList.append((userData, ()))
        closureSetUserData()
    }
}
