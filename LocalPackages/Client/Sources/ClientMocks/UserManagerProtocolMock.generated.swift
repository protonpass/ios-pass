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

    // MARK: - userDatas
    public var invokedUserDatasSetter = false
    public var invokedUserDatasSetterCount = 0
    public var invokedUserDatas: CurrentValueSubject<[UserData], Never>?
    public var invokedUserDatasList = [CurrentValueSubject<[UserData], Never>?]()
    public var invokedUserDatasGetter = false
    public var invokedUserDatasGetterCount = 0
    public var stubbedUserDatas: CurrentValueSubject<[UserData], Never>!
    public var userDatas: CurrentValueSubject<[UserData], Never> {
        set {
            invokedUserDatasSetter = true
            invokedUserDatasSetterCount += 1
            invokedUserDatas = newValue
            invokedUserDatasList.append(newValue)
        } get {
            invokedUserDatasGetter = true
            invokedUserDatasGetterCount += 1
            return stubbedUserDatas
        }
    }
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
    // MARK: - activeUserId
    public var invokedActiveUserIdSetter = false
    public var invokedActiveUserIdSetterCount = 0
    public var invokedActiveUserId: CurrentValueSubject<String?, Never>?
    public var invokedActiveUserIdList = [CurrentValueSubject<String?, Never>?]()
    public var invokedActiveUserIdGetter = false
    public var invokedActiveUserIdGetterCount = 0
    public var stubbedActiveUserId: CurrentValueSubject<String?, Never>!
    public var activeUserId: CurrentValueSubject<String?, Never> {
        set {
            invokedActiveUserIdSetter = true
            invokedActiveUserIdSetterCount += 1
            invokedActiveUserId = newValue
            invokedActiveUserIdList.append(newValue)
        } get {
            invokedActiveUserIdGetter = true
            invokedActiveUserIdGetterCount += 1
            return stubbedActiveUserId
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
    // MARK: - add
    public var addUserDataIsActiveThrowableError3: Error?
    public var closureAdd: () -> () = {}
    public var invokedAddfunction = false
    public var invokedAddCount = 0
    public var invokedAddParameters: (userData: UserData, isActive: Bool)?
    public var invokedAddParametersList = [(userData: UserData, isActive: Bool)]()

    public func add(userData: UserData, isActive: Bool) async throws {
        invokedAddfunction = true
        invokedAddCount += 1
        invokedAddParameters = (userData, isActive)
        invokedAddParametersList.append((userData, isActive))
        if let error = addUserDataIsActiveThrowableError3 {
            throw error
        }
        closureAdd()
    }
    // MARK: - switchActiveUser
    public var switchActiveUserWithThrowableError4: Error?
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
        if let error = switchActiveUserWithThrowableError4 {
            throw error
        }
        closureSwitchActiveUser()
    }
    // MARK: - getAllUser
    public var getAllUserThrowableError5: Error?
    public var closureGetAllUser: () -> () = {}
    public var invokedGetAllUserfunction = false
    public var invokedGetAllUserCount = 0
    public var stubbedGetAllUserResult: [UserData]!

    public func getAllUser() async throws -> [UserData] {
        invokedGetAllUserfunction = true
        invokedGetAllUserCount += 1
        if let error = getAllUserThrowableError5 {
            throw error
        }
        closureGetAllUser()
        return stubbedGetAllUserResult
    }
    // MARK: - remove
    public var removeUserIdThrowableError6: Error?
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
        if let error = removeUserIdThrowableError6 {
            throw error
        }
        closureRemove()
    }
    // MARK: - getActiveUserId
    public var getActiveUserIdThrowableError7: Error?
    public var closureGetActiveUserId: () -> () = {}
    public var invokedGetActiveUserIdfunction = false
    public var invokedGetActiveUserIdCount = 0
    public var stubbedGetActiveUserIdResult: String!

    public func getActiveUserId() async throws -> String {
        invokedGetActiveUserIdfunction = true
        invokedGetActiveUserIdCount += 1
        if let error = getActiveUserIdThrowableError7 {
            throw error
        }
        closureGetActiveUserId()
        return stubbedGetActiveUserIdResult
    }
    // MARK: - getUserData
    public var closureGetUserData: () -> () = {}
    public var invokedGetUserDatafunction = false
    public var invokedGetUserDataCount = 0
    public var stubbedGetUserDataResult: UserData?

    public func getUserData() -> UserData? {
        invokedGetUserDatafunction = true
        invokedGetUserDataCount += 1
        closureGetUserData()
        return stubbedGetUserDataResult
    }
    // MARK: - setUserData
    public var closureSetUserData: () -> () = {}
    public var invokedSetUserDatafunction = false
    public var invokedSetUserDataCount = 0
    public var invokedSetUserDataParameters: (userData: UserData, isActive: Bool)?
    public var invokedSetUserDataParametersList = [(userData: UserData, isActive: Bool)]()

    public func setUserData(_ userData: UserData, isActive: Bool) {
        invokedSetUserDatafunction = true
        invokedSetUserDataCount += 1
        invokedSetUserDataParameters = (userData, isActive)
        invokedSetUserDataParametersList.append((userData, isActive))
        closureSetUserData()
    }
    // MARK: - getActiveUserIdNonisolated
    public var getActiveUserIdNonisolatedThrowableError10: Error?
    public var closureGetActiveUserIdNonisolated: () -> () = {}
    public var invokedGetActiveUserIdNonisolatedfunction = false
    public var invokedGetActiveUserIdNonisolatedCount = 0
    public var stubbedGetActiveUserIdNonisolatedResult: String!

    public func getActiveUserIdNonisolated() throws -> String {
        invokedGetActiveUserIdNonisolatedfunction = true
        invokedGetActiveUserIdNonisolatedCount += 1
        if let error = getActiveUserIdNonisolatedThrowableError10 {
            throw error
        }
        closureGetActiveUserIdNonisolated()
        return stubbedGetActiveUserIdNonisolatedResult
    }
    // MARK: - getUnwrappedUserData
    public var getUnwrappedUserDataThrowableError11: Error?
    public var closureGetUnwrappedUserData: () -> () = {}
    public var invokedGetUnwrappedUserDatafunction = false
    public var invokedGetUnwrappedUserDataCount = 0
    public var stubbedGetUnwrappedUserDataResult: UserData!

    public func getUnwrappedUserData() throws -> UserData {
        invokedGetUnwrappedUserDatafunction = true
        invokedGetUnwrappedUserDataCount += 1
        if let error = getUnwrappedUserDataThrowableError11 {
            throw error
        }
        closureGetUnwrappedUserData()
        return stubbedGetUnwrappedUserDataResult
    }
}
