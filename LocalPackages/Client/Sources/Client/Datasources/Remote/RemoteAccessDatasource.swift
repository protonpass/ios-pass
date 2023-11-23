//
// RemoteAccessDatasource.swift
// Proton Pass - Created on 04/05/2023.
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

import Entities

public protocol RemoteAccessDatasourceProtocol {
    func getAccess() async throws -> Access
}

public final class RemoteAccessDatasource: RemoteDatasource, RemoteAccessDatasourceProtocol {
    public func getAccess() async throws -> Access {
        let endpoint = CheckAccessEndpoint()
        let response = try await exec(endpoint: endpoint)
        return response.access
    }
}
