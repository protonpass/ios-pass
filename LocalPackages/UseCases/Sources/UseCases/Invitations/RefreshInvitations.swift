//
//
// RefreshInvitations.swift
// Proton Pass - Created on 31/07/2023.
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

import Client

public protocol RefreshInvitationsUseCase: Sendable {
    func execute() async throws
}

public extension RefreshInvitationsUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class RefreshInvitations: RefreshInvitationsUseCase {
    private let inviteRepository: any InviteRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol

    public init(inviteRepository: any InviteRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol) {
        self.inviteRepository = inviteRepository
        self.accessRepository = accessRepository
    }

    public func execute() async throws {
        await inviteRepository.refreshInvites()
    }
}
