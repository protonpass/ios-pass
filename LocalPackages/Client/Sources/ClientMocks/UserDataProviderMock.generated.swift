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

//import Client
//import Entities
//import ProtonCoreLogin
//
//public final class UserDataProviderMock: @unchecked Sendable, UserDataProvider {
//
//    public init() {}
//
//    // MARK: - getUserData
//    public var closureGetUserData: () -> () = {}
//    public var invokedGetUserDatafunction = false
//    public var invokedGetUserDataCount = 0
//    public var stubbedGetUserDataResult: UserData?
//
//    public func getUserData() -> UserData? {
//        invokedGetUserDatafunction = true
//        invokedGetUserDataCount += 1
//        closureGetUserData()
//        return stubbedGetUserDataResult
//    }
//    // MARK: - updateUserData
//    public var closureUpdateUserData: () -> () = {}
//    public var invokedUpdateUserDatafunction = false
//    public var invokedUpdateUserDataCount = 0
//    public var invokedUpdateUserDataParameters: (userId: String?, userData: UserData?)?
//    public var invokedUpdateUserDataParametersList = [(userId: String?, userData: UserData?)]()
//
//    public func updateUserData(userId: String?, _ userData: UserData?) {
//        invokedUpdateUserDatafunction = true
//        invokedUpdateUserDataCount += 1
//        invokedUpdateUserDataParameters = (userId, userData)
//        invokedUpdateUserDataParametersList.append((userId, userData))
//        closureUpdateUserData()
//    }
//}
