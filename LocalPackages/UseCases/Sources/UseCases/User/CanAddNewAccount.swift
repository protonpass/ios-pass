//
// CanAddNewAccount.swift
// Proton Pass - Created on 29/07/2024.
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

import Client

public protocol CanAddNewAccountUseCase: Sendable {
    func execute(userId: String) async throws -> Bool
}

public extension CanAddNewAccountUseCase {
    func callAsFunction(userId: String) async throws -> Bool {
        try await execute(userId: userId)
    }
}

public final class CanAddNewAccount: CanAddNewAccountUseCase {
    private let localDatasource: any LocalAccessDatasourceProtocol
    private let remoteDatasource: any RemoteAccessDatasourceProtocol
    private let authManager: any AuthManagerProtocol

    public init(localDatasource: any LocalAccessDatasourceProtocol,
                remoteDatasource: any RemoteAccessDatasourceProtocol,
                authManager: any AuthManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.authManager = authManager
    }

    public func execute(userId: String) async throws -> Bool {
        let access = try await remoteDatasource.getAccess(userId: userId)
        let accesses = try await localDatasource.getAllAccesses()
        if accesses.contains(where: \.access.plan.isFreeUser),
           access.plan.isFreeUser {
            authManager.removeCredentials(userId: userId)
            return false
        }
        return true
    }
}
