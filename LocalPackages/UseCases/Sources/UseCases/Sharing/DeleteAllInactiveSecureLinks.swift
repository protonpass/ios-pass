//
// DeleteAllInactiveSecureLinks.swift
// Proton Pass - Created on 19/06/2024.
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

import Client

public protocol DeleteAllInactiveSecureLinksUseCase: Sendable {
    func execute() async throws
}

public extension DeleteAllInactiveSecureLinksUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class DeleteAllInactiveSecureLinks: DeleteAllInactiveSecureLinksUseCase {
    private let datasource: any RemoteSecureLinkDatasourceProtocol
    private let manager: any SecureLinkManagerProtocol
    private let userManager: any UserManagerProtocol

    public init(datasource: any RemoteSecureLinkDatasourceProtocol,
                userManager: any UserManagerProtocol,
                manager: any SecureLinkManagerProtocol) {
        self.datasource = datasource
        self.userManager = userManager
        self.manager = manager
    }

    public func execute() async throws {
        let userId = try await userManager.getActiveUserId()
        try await datasource.deleteAllInactiveLinks(userId: userId)
        try await manager.updateSecureLinks()
    }
}
