//
//
// GetPendingInvitationsForShare.swift
// Proton Pass - Created on 03/08/2023.
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
import Entities

public protocol GetPendingInvitationsForShareUseCase: Sendable {
    func execute(with shareId: String) async throws -> ShareInvites
}

public extension GetPendingInvitationsForShareUseCase {
    func callAsFunction(with shareId: String) async throws -> ShareInvites {
        try await execute(with: shareId)
    }
}

public final class GetPendingInvitationsForShare: GetPendingInvitationsForShareUseCase {
    private let repository: ShareInviteRepositoryProtocol

    public init(repository: ShareInviteRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(with shareId: String) async throws -> ShareInvites {
        try await repository.getAllPendingInvites(shareId: shareId)
    }
}
