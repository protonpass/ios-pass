// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
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
    // MARK: - allUserAccounts
    public var invokedAllUserAccountsSetter = false
    public var invokedAllUserAccountsSetterCount = 0
    public var invokedAllUserAccounts: CurrentValueSubject<[UserData], Never>?
    public var invokedAllUserAccountsList = [CurrentValueSubject<[UserData], Never>?]()
    public var invokedAllUserAccountsGetter = false
    public var invokedAllUserAccountsGetterCount = 0
    public var stubbedAllUserAccounts: CurrentValueSubject<[UserData], Never>!
    public var allUserAccounts: CurrentValueSubject<[UserData], Never> {
        set {
            invokedAllUserAccountsSetter = true
            invokedAllUserAccountsSetterCount += 1
            invokedAllUserAccounts = newValue
            invokedAllUserAccountsList.append(newValue)
        } get {
            invokedAllUserAccountsGetter = true
            invokedAllUserAccountsGetterCount += 1
            return stubbedAllUserAccounts
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
    // MARK: - upsertAndMarkAsActive
    public var upsertAndMarkAsActiveUserDataThrowableError3: Error?
    public var closureUpsertAndMarkAsActive: () -> () = {}
    public var invokedUpsertAndMarkAsActivefunction = false
    public var invokedUpsertAndMarkAsActiveCount = 0
    public var invokedUpsertAndMarkAsActiveParameters: (userData: UserData, Void)?
    public var invokedUpsertAndMarkAsActiveParametersList = [(userData: UserData, Void)]()

    public func upsertAndMarkAsActive(userData: UserData) async throws {
        invokedUpsertAndMarkAsActivefunction = true
        invokedUpsertAndMarkAsActiveCount += 1
        invokedUpsertAndMarkAsActiveParameters = (userData, ())
        invokedUpsertAndMarkAsActiveParametersList.append((userData, ()))
        if let error = upsertAndMarkAsActiveUserDataThrowableError3 {
            throw error
        }
        closureUpsertAndMarkAsActive()
    }
    // MARK: - switchActiveUser
    public var switchActiveUserWithOnMemoryThrowableError4: Error?
    public var closureSwitchActiveUser: () -> () = {}
    public var invokedSwitchActiveUserfunction = false
    public var invokedSwitchActiveUserCount = 0
    public var invokedSwitchActiveUserParameters: (userId: String, onMemory: Bool)?
    public var invokedSwitchActiveUserParametersList = [(userId: String, onMemory: Bool)]()

    public func switchActiveUser(with userId: String, onMemory: Bool) async throws {
        invokedSwitchActiveUserfunction = true
        invokedSwitchActiveUserCount += 1
        invokedSwitchActiveUserParameters = (userId, onMemory)
        invokedSwitchActiveUserParametersList.append((userId, onMemory))
        if let error = switchActiveUserWithOnMemoryThrowableError4 {
            throw error
        }
        closureSwitchActiveUser()
    }
    // MARK: - getAllUsers
    public var getAllUsersThrowableError5: Error?
    public var closureGetAllUsers: () -> () = {}
    public var invokedGetAllUsersfunction = false
    public var invokedGetAllUsersCount = 0
    public var stubbedGetAllUsersResult: [UserData]!

    public func getAllUsers() async throws -> [UserData] {
        invokedGetAllUsersfunction = true
        invokedGetAllUsersCount += 1
        if let error = getAllUsersThrowableError5 {
            throw error
        }
        closureGetAllUsers()
        return stubbedGetAllUsersResult
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
    // MARK: - cleanAllUsers
    public var cleanAllUsersThrowableError7: Error?
    public var closureCleanAllUsers: () -> () = {}
    public var invokedCleanAllUsersfunction = false
    public var invokedCleanAllUsersCount = 0

    public func cleanAllUsers() async throws {
        invokedCleanAllUsersfunction = true
        invokedCleanAllUsersCount += 1
        if let error = cleanAllUsersThrowableError7 {
            throw error
        }
        closureCleanAllUsers()
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
