//
// RemoteAccountDatasource.swift
// Proton Pass - Created on 26/03/2024.
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

import Foundation
import ProtonCoreDataModel

public protocol RemoteAccountDatasourceProtocol: Sendable {
    func getAccountRecoveryInfo(userId: String) async throws -> AccountRecovery?
}

public final class RemoteAccountDatasource: RemoteDatasource, RemoteAccountDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteAccountDatasource {
    func getAccountRecoveryInfo(userId: String) async throws -> AccountRecovery? {
        let getUserEndpoint = GetUserEndpoint()
        let getUserResponse = try await exec(userId: userId, endpoint: getUserEndpoint)
        return getUserResponse.user.accountRecovery
    }
}
