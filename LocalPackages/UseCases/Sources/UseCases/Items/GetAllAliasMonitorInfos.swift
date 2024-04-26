//
//
// GetAllAliasMonitorInfos.swift
// Proton Pass - Created on 19/04/2024.
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
import Entities

public protocol GetAllAliasMonitorInfoUseCase: Sendable {
    func execute() async throws -> [AliasMonitorInfo]
}

public extension GetAllAliasMonitorInfoUseCase {
    func callAsFunction() async throws -> [AliasMonitorInfo] {
        try await execute()
    }
}

public final class GetAllAliasMonitorInfos: GetAllAliasMonitorInfoUseCase {
    private let getAllAliasesUseCase: any GetAllAliasesUseCase
    private let repository: any PassMonitorRepositoryProtocol

    public init(getAllAliasesUseCase: any GetAllAliasesUseCase,
                repository: any PassMonitorRepositoryProtocol) {
        self.getAllAliasesUseCase = getAllAliasesUseCase
        self.repository = repository
    }

    public func execute() async throws -> [AliasMonitorInfo] {
        let aliases = try await getAllAliasesUseCase()

        return try await withThrowingTaskGroup(of: AliasMonitorInfo.self,
                                               returning: [AliasMonitorInfo].self) { group in
            for alias in aliases {
                group.addTask { [weak self] in
                    guard let self, alias.item.isBreached else { return AliasMonitorInfo(alias: alias,
                                                                                         breaches: nil) }
                    let breach = try await repository.getBreachesForAlias(sharedId: alias.shareId,
                                                                          itemId: alias.itemId)
                    return AliasMonitorInfo(alias: alias, breaches: breach)
                }
            }
            var results = [AliasMonitorInfo]()
            for try await aliasMonitorInfo in group {
                results.append(aliasMonitorInfo)
            }
            return results
        }
    }
}
