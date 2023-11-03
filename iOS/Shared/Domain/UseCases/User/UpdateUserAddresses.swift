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

import ProtonCoreAuthentication
import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreNetworking

protocol UpdateUserAddressesUseCase: Sendable {
    func execute() async throws -> [Address]?
}

extension UpdateUserAddressesUseCase {
    func callAsFunction() async throws -> [Address]? {
        try await execute()
    }
}

final class UpdateUserAddresses: UpdateUserAddressesUseCase {
    private let authenticator: AuthenticatorInterface
    private let sharedDataContainer: SharedDataContainer

    init(sharedDataContainer: SharedDataContainer,
         authenticator: AuthenticatorInterface) {
        self.sharedDataContainer = sharedDataContainer
        self.authenticator = authenticator
    }

    func execute() async throws -> [Address]? {
        let newAppData = SharedDataContainer.shared.appData()
        guard let userdata = newAppData.getUserData() else {
            return nil
        }
        let newAddresses = try await authenticator.getAddresses(userdata.getCredential)

        let newUserData = UserData(credential: userdata.credential,
                                   user: userdata.user,
                                   salts: userdata.salts,
                                   passphrases: userdata.passphrases,
                                   addresses: newAddresses,
                                   scopes: userdata.scopes)

        newAppData.setUserData(newUserData)

        SharedDataContainer.shared.appData.register { newAppData }

        return newAddresses
    }
}

private extension AuthenticatorInterface {
    func getAddresses(_ credential: Credential?) async throws -> [Address] {
        try await withCheckedThrowingContinuation { continuation in
            getAddresses(credential) { result in
                continuation.resume(with: result)
            }
        }
    }
}
