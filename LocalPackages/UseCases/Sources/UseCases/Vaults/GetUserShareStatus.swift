//
//
// GetUserShareStatus.swift
// Proton Pass - Created on 13/10/2023.
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

public protocol GetUserShareStatusUseCase: Sendable {
    func execute(for vault: Share) -> UserShareStatus
}

public extension GetUserShareStatusUseCase {
    func callAsFunction(for vault: Share) -> UserShareStatus {
        execute(for: vault)
    }
}

public enum UserShareStatus {
    case canShare
    case cantShare
    case upsell
}

public final class GetUserShareStatus: @unchecked Sendable, GetUserShareStatusUseCase {
    private var plan: Plan?

    public init(accessRepository: any AccessRepositoryProtocol) {
        Task { [weak self] in
            guard let self else {
                return
            }
            plan = try? await accessRepository.getPlan(userId: nil)
        }
    }

    public func execute(for vault: Share) -> UserShareStatus {
        guard let plan, vault.isAdmin || vault.isOwner else {
            return .cantShare
        }

        if plan.isFreeUser {
            return vault.totalOverallMembers >= 3 ? .upsell : .canShare
        }
        return vault.canShareWithMorePeople ? .canShare : .cantShare
    }
}
