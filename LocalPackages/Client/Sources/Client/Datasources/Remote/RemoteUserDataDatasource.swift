//
// RemoteUserDataDatasource.swift
// Proton Pass - Created on 16/10/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Entities
import ProtonCoreAuthentication
import ProtonCoreDataModel
import ProtonCoreLogin

public protocol RemoteUserDataDatasourceProtocol: Sendable {
    func getUpdatedUserData(_ oldUserData: UserData) async throws -> UserData
}

public final class RemoteUserDataDatasource: RemoteDatasource, RemoteUserDataDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteUserDataDatasource {
    func getUpdatedUserData(_ oldUserData: UserData) async throws -> UserData {
        let apiService = try getApiService(userId: oldUserData.user.ID)
        let authenticator = Authenticator(api: apiService)
        let updatedUser = try await authenticator.getUserInfo()
        let updatedAddresses = try await authenticator.getAddresses()

        let oldSaltsByID = Dictionary(uniqueKeysWithValues: oldUserData.salts.map { ($0.ID, $0) })
        let updatedKeySalts = updatedUser.keys.map { key in
            oldSaltsByID[key.keyID] ?? KeySalt(ID: key.keyID, keySalt: nil)
        }

        var updatedPassphrases: [String: String] = [:]

        let uniqueOldPassphrases = Set(oldUserData.passphrases.map(\.value))
        let builder = BuildAndValidatePassphrases()

        for oldPassphrase in uniqueOldPassphrases {
            if let passphrases = try builder.buildAndValidatePassphrases(passphrase: oldPassphrase,
                                                                         salts: updatedKeySalts,
                                                                         userKeys: updatedUser.keys) {
                updatedPassphrases.merge(passphrases, uniquingKeysWith: { $1 })
            }
        }

        if updatedPassphrases.isEmpty {
            throw PassError.crypto(.failedToBuildPassphrases)
        }

        return .init(credential: oldUserData.credential,
                     user: updatedUser,
                     salts: updatedKeySalts,
                     passphrases: updatedPassphrases,
                     addresses: updatedAddresses,
                     scopes: oldUserData.scopes)
    }
}
