//
//
// RevokeUserShareAccess.swift
// Proton Pass - Created on 04/08/2023.
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

@preconcurrency import Client

protocol RevokeUserShareAccessUseCase: Sendable {
    func execute(with userShareId: String, and shareId: String) async throws
}

extension RevokeUserShareAccessUseCase {
    func callAsFunction(with userShareId: String, and shareId: String) async throws {
        try await execute(with: userShareId, and: shareId)
    }
}

final class RevokeUserShareAccess: RevokeUserShareAccessUseCase {
    private let repository: ShareRepositoryProtocol

    init(repository: ShareRepositoryProtocol) {
        self.repository = repository
    }

    func execute(with userShareId: String, and shareId: String) async throws {
        try await repository.deleteUserShare(userId: userShareId, shareId: shareId)
    }
}
