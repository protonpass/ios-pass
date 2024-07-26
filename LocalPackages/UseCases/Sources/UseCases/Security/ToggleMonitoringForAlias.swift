//
//
// ToggleMonitoringForAlias.swift
// Proton Pass - Created on 24/04/2024.
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

public protocol ToggleMonitoringForAliasUseCase: Sendable {
    func execute(userId: String, alias: ItemContent) async throws
}

public extension ToggleMonitoringForAliasUseCase {
    func callAsFunction(userId: String, alias: ItemContent) async throws {
        try await execute(userId: userId, alias: alias)
    }
}

public final class ToggleMonitoringForAlias: ToggleMonitoringForAliasUseCase {
    private let repository: any PassMonitorRepositoryProtocol
    private let getAllAliasMonitorInfo: any GetAllAliasMonitorInfoUseCase

    public init(repository: any PassMonitorRepositoryProtocol,
                getAllAliasMonitorInfo: any GetAllAliasMonitorInfoUseCase) {
        self.repository = repository
        self.getAllAliasMonitorInfo = getAllAliasMonitorInfo
    }

    public func execute(userId: String, alias: ItemContent) async throws {
        try await repository.toggleMonitoringForAlias(sharedId: alias.shareId,
                                                      itemId: alias.itemId,
                                                      shouldMonitor: !alias.item.monitoringDisabled)
        let aliasesMonitorInfos = try await getAllAliasMonitorInfo(userId: userId)
        repository.darkWebDataSectionUpdate.send(.aliases(aliasesMonitorInfos))
    }
}
