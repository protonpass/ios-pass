//
// GetPassUsers.swift
// Proton Pass - Created on 05/09/2024.
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
import Entities

public protocol GetPassUsersUseCase: Sendable {
    func execute() async throws -> [PassUser]
}

public extension GetPassUsersUseCase {
    func callAsFunction() async throws -> [PassUser] {
        try await execute()
    }
}

public final class GetPassUsers: GetPassUsersUseCase {
    private let userManager: any UserManagerProtocol
    private let localAccessDatasource: any LocalAccessDatasourceProtocol

    public init(userManager: any UserManagerProtocol,
                localAccessDatasource: any LocalAccessDatasourceProtocol) {
        self.userManager = userManager
        self.localAccessDatasource = localAccessDatasource
    }

    public func execute() async throws -> [PassUser] {
        let userDatas = try await userManager.getAllUsers()
        guard !userDatas.isEmpty else {
            throw PassError.userManager(.noUserDataFound)
        }

        var passUsers = [PassUser]()

        for userData in userDatas {
            let userId = userData.user.ID
            if let access = try await localAccessDatasource.getAccess(userId: userId) {
                passUsers.append(.init(id: userId,
                                       displayName: userData.user.displayName,
                                       email: userData.user.email,
                                       plan: access.access.plan))
            } else {
                throw PassError.userManager(.noAccessFound(userId))
            }
        }

        return passUsers
    }
}
