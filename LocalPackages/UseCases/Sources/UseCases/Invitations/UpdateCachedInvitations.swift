//
//
// UpdateCachedInvitations.swift
// Proton Pass - Created on 01/08/2023.
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

public protocol UpdateCachedInvitationsUseCase: Sendable {
    func execute(for inviteToken: String) async
}

public extension UpdateCachedInvitationsUseCase {
    func callAsFunction(for inviteToken: String) async {
        await execute(for: inviteToken)
    }
}

public final class UpdateCachedInvitations: UpdateCachedInvitationsUseCase {
    private let repository: InviteRepositoryProtocol

    public init(repository: InviteRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(for inviteToken: String) async {
        await repository.removeCachedInvite(containing: inviteToken)
    }
}
