//
//
// GetLoginSecurityIssues.swift
// Proton Pass - Created on 07/03/2024.
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

public protocol GetLoginSecurityIssuesUseCase: Sendable {
    func execute(itemId: String) -> AnyPublisher<[SecurityWeakness]?, Never>
}

public extension GetLoginSecurityIssuesUseCase {
    func callAsFunction(itemId: String) -> AnyPublisher<[SecurityWeakness]?, Never> {
        execute(itemId: itemId)
    }
}

public final class GetLoginSecurityIssues: GetLoginSecurityIssuesUseCase {
    private let passMonitorRepository: any PassMonitorRepositoryProtocol

    public init(passMonitorRepository: any PassMonitorRepositoryProtocol) {
        self.passMonitorRepository = passMonitorRepository
    }

    public func execute(itemId: String) -> AnyPublisher<[SecurityWeakness]?, Never> {
        passMonitorRepository.itemsWithSecurityIssues
            .map { items -> [SecurityWeakness]? in
                items.first { $0.item.itemId == itemId }?.weaknesses
            }.eraseToAnyPublisher()
    }
}
