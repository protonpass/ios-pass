//
// UserDataProvider.swift
// Proton Pass - Created on 03/11/2023.
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
//

import Entities
import ProtonCoreLogin
import ProtonCoreNetworking

public typealias FullDataProvider = CredentialProvider & ResetingPrototocol & SymmetricKeyProvider &
    UserDataProvider

// sourcery: AutoMockable
public protocol UserDataProvider: Sendable {
    func getUserData() -> UserData?
    func setUserData(_ userData: UserData?)
}

public extension UserDataProvider {
    func getUserId() throws -> String {
        guard let userData = getUserData() else {
            throw PassError.noUserData
        }
        return userData.user.ID
    }

    func getUnwrappedUserData() throws -> UserData {
        guard let userData = getUserData() else {
            throw PassError.noUserData
        }
        return userData
    }
}

// sourcery: AutoMockable
public protocol CredentialProvider: Sendable {
    func setCredentials(_ credential: AuthCredential?)
    func getCredentials() -> AuthCredential?
}

// sourcery: AutoMockable
public protocol ResetingPrototocol: Sendable {
    func resetData()
}
