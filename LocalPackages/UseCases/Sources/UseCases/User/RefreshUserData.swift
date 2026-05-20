//
// RefreshUserData.swift
// Proton Pass - Created on 17/04/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Entities

public protocol RefreshUserDataUseCase {
    func callAsFunction(userId: String) async throws
}

public struct RefreshUserData: RefreshUserDataUseCase {
    private let remoteDatasource: any RemoteUserDataDatasourceProtocol
    private let userManager: any UserManagerProtocol

    public init(remoteDatasource: any RemoteUserDataDatasourceProtocol,
                userManager: any UserManagerProtocol) {
        self.remoteDatasource = remoteDatasource
        self.userManager = userManager
    }

    public func callAsFunction(userId: String) async throws {
        guard let userData = try await userManager.getUserData(userId) else {
            throw PassError.userManager(.userNotFound(userId: userId))
        }
        let updatedUserData = try await remoteDatasource.getUpdatedUserData(userData)
        try await userManager.upsertAndSetUpAgain(userData: updatedUserData)
    }
}
