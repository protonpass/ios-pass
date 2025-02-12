//
//
// UpdateUserAddresses.swift
// Proton Pass - Created on 17/10/2023.
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

import Client

@preconcurrency import ProtonCoreAuthentication
@preconcurrency import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreNetworking

public protocol UpdateUserAddressesUseCase: Sendable {
    func execute() async throws -> [Address]?
}

public extension UpdateUserAddressesUseCase {
    func callAsFunction() async throws -> [Address]? {
        try await execute()
    }
}

public final class UpdateUserAddresses: UpdateUserAddressesUseCase {
    private let userManager: any UserManagerProtocol
    private let apiServicing: any APIManagerProtocol

    public init(userManager: any UserManagerProtocol,
                apiServicing: any APIManagerProtocol) {
        self.userManager = userManager
        self.apiServicing = apiServicing
    }

    public func execute() async throws -> [Address]? {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let apiService = try apiServicing.getApiService(userId: userData.user.ID)
        let authenticator = Authenticator(api: apiService)

        let newAddresses = try await authenticator.getAddresses(userData.getCredential)

        let newUserData = UserData(credential: userData.credential,
                                   user: userData.user,
                                   salts: userData.salts,
                                   passphrases: userData.passphrases,
                                   addresses: newAddresses,
                                   scopes: userData.scopes)

        try await userManager.upsertAndMarkAsActive(userData: newUserData)
        return newAddresses
    }
}

// swiftlint:disable:next todo
// TODO: check with account eam for the implementation of address_v2 and sendable conformance.
extension Address: @unchecked @retroactive Sendable {}
