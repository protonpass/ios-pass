//
//
// GetUserPlan.swift
// Proton Pass - Created on 31/01/2024.
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
//

import Client
import Combine
import Entities

public protocol GetUserPlanUseCase: Sendable {
    func execute() -> CurrentValueSubject<Plan?, Never>
}

public extension GetUserPlanUseCase {
    func callAsFunction() -> CurrentValueSubject<Plan?, Never> {
        execute()
    }
}

public final class GetUserPlan: @unchecked Sendable, GetUserPlanUseCase {
    private let repository: any AccessRepositoryProtocol
    private let plan: CurrentValueSubject<Plan?, Never> = .init(nil)

    public init(repository: any AccessRepositoryProtocol) {
        self.repository = repository
        refreshPlan()
    }

    public func execute() -> CurrentValueSubject<Plan?, Never> {
        plan
    }
}

private extension GetUserPlan {
    func refreshPlan() {
        Task { [weak self] in
            guard let self else { return }
            let localPlan = try? await repository.getPlan()
            // First get local plan to optimistically display it
            // and then try to refresh the plan to have it updated
            plan.send(localPlan)
            let newPlan = try? await repository.refreshAccess().plan
            guard newPlan != localPlan else {
                return
            }
            plan.send(localPlan)
        }
    }
}
