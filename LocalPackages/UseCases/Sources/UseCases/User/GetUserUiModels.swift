//
// GetUserUiModels.swift
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
@preconcurrency import ProtonCoreLogin

public protocol GetUserUiModelsUseCase: Sendable {
    func execute() async throws -> [UserUiModel]
}

public extension GetUserUiModelsUseCase {
    func callAsFunction() async throws -> [UserUiModel] {
        try await execute()
    }
}

public final class GetUserUiModels: GetUserUiModelsUseCase {
    private let userManager: any UserManagerProtocol
    private let localAccessDatasource: any LocalAccessDatasourceProtocol

    public init(userManager: any UserManagerProtocol,
                localAccessDatasource: any LocalAccessDatasourceProtocol) {
        self.userManager = userManager
        self.localAccessDatasource = localAccessDatasource
    }

    public func execute() async throws -> [UserUiModel] {
        let userDatas = try await userManager.getAllUsers()
        guard !userDatas.isEmpty else {
            throw PassError.userManager(.noUserDataFound)
        }

        return try await withThrowingTaskGroup(of: UserUiModel.self) { [weak self] group in
            guard let self else {
                throw PassError.unexpectedError
            }
            for userData in userDatas {
                group.addTask {
                    let userId = userData.user.ID
                    guard let access = try await self.localAccessDatasource.getAccess(userId: userId) else {
                        throw PassError.userManager(.noAccessFound(userId))
                    }
                    return .init(id: userId,
                                 displayName: userData.user.displayName,
                                 email: userData.user.email,
                                 plan: access.access.plan)
                }
            }

            var uiModels = [UserUiModel]()
            uiModels.reserveCapacity(userDatas.count)
            for try await model in group {
                uiModels.append(model)
            }
            return uiModels
        }
    }
}

extension UserData: @retroactive @unchecked Sendable {}
