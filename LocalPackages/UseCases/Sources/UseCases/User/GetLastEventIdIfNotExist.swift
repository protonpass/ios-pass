//
// GetLastEventIdIfNotExist.swift
// Proton Pass - Created on 21/05/2025.
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
//

import Client
import Foundation

public protocol GetLastEventIdIfNotExistUseCase: Sendable {
    func execute(userId: String) async throws
}

public extension GetLastEventIdIfNotExistUseCase {
    func callAsFunction(userId: String) async throws {
        try await execute(userId: userId)
    }
}

public final class GetLastEventIdIfNotExist: GetLastEventIdIfNotExistUseCase {
    private let localDatasource: any LocalUserEventIdDatasourceProtocol
    private let remoteDatasource: any RemoteUserEventsDatasourceProtocol

    public init(localDatasource: any LocalUserEventIdDatasourceProtocol,
                remoteDatasource: any RemoteUserEventsDatasourceProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
    }

    public func execute(userId: String) async throws {
        guard try await localDatasource.getLastEventId(userId: userId) == nil else {
            return
        }

        let lastEventId = try await remoteDatasource.getLastEventId(userId: userId)
        try await localDatasource.upsertLastEventId(userId: userId,
                                                    lastEventId: lastEventId)
    }
}
