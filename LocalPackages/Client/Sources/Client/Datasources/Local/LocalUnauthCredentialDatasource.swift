//
// LocalUnauthCredentialDatasource.swift
// Proton Pass - Created on 17/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Foundation
import ProtonCoreNetworking

private let kUnauthCredentialKey = "UnauthCredential"

protocol LocalUnauthCredentialDatasourceProtocol: Sendable {
    func getUnauthCredential() throws -> AuthCredential?
    func upsertUnauthCredential(_ credential: AuthCredential) throws
    func removeUnauthCredential()
}

public final class LocalUnauthCredentialDatasource: Sendable, LocalUnauthCredentialDatasourceProtocol {
    private let userDefault: UserDefaults

    public init(userDefault: UserDefaults) {
        self.userDefault = userDefault
    }
}

public extension LocalUnauthCredentialDatasource {
    func getUnauthCredential() throws -> AuthCredential? {
        guard let data = userDefault.data(forKey: kUnauthCredentialKey) else {
            return nil
        }
        return try JSONDecoder().decode(AuthCredential.self, from: data)
    }

    func upsertUnauthCredential(_ credential: AuthCredential) throws {
        let data = try JSONEncoder().encode(credential)
        userDefault.set(data, forKey: kUnauthCredentialKey)
    }

    func removeUnauthCredential() {
        userDefault.removeObject(forKey: kUnauthCredentialKey)
    }
}
