//
// CredentialProvider.swift
// Proton Pass - Created on 23/11/2023.
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

import ProtonCoreNetworking

public protocol CredentialProvider {
    func getCredential() -> AuthCredential?
    func setCredential(_ credential: AuthCredential?)

    var isAuthenticated: Bool { get }

    // Should be removed after session forking
    func migrateToSeparatedCredentials()
}

public extension CredentialProvider {
    var isAuthenticated: Bool {
        guard let credential = getCredential() else {
            return false
        }
        return !credential.isForUnauthenticatedSession
    }
}
