//
//
// GetUsersLinkedToShare.swift
// Proton Pass - Created on 02/08/2023.
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

public protocol GetUsersLinkedToShareUseCase: Sendable {
    func execute(with share: Share, itemId: String?, lastToken: String?) async throws
        -> PaginatedUsersLinkedToShare
}

public extension GetUsersLinkedToShareUseCase {
    func callAsFunction(with share: Share,
                        itemId: String? = nil,
                        lastToken: String? = nil) async throws -> PaginatedUsersLinkedToShare {
        try await execute(with: share, itemId: itemId, lastToken: lastToken)
    }
}

public final class GetUsersLinkedToShare: GetUsersLinkedToShareUseCase {
    private let repository: any ShareRepositoryProtocol

    public init(repository: any ShareRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(with share: Share,
                        itemId: String?,
                        lastToken: String?) async throws -> PaginatedUsersLinkedToShare {
        if let itemId {
            try await repository.getUsersLinkedToItemShare(to: share.id, itemId: itemId, lastToken: lastToken)
        } else {
            try await repository.getUsersLinkedToVaultShare(to: share.id, lastToken: lastToken)
        }
    }
}
