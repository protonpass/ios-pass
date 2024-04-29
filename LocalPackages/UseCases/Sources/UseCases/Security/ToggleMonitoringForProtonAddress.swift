//
//
// ToggleMonitoringForProtonAddress.swift
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

public protocol ToggleMonitoringForProtonAddressUseCase: Sendable {
    func execute(address: ProtonAddress) async throws
}

public extension ToggleMonitoringForProtonAddressUseCase {
    func callAsFunction(address: ProtonAddress) async throws {
        try await execute(address: address)
    }
}

public final class ToggleMonitoringForProtonAddress: ToggleMonitoringForProtonAddressUseCase {
    private let repository: any PassMonitorRepositoryProtocol

    public init(repository: any PassMonitorRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(address: ProtonAddress) async throws {
        try await repository.toggleMonitoringFor(address: address,
                                                 shouldMonitor: address.monitoringDisabled)
        let refreshUserBreaches = try await repository.refreshUserBreaches()
        repository.darkWebDataSectionUpdate.send(.protonAddresses(refreshUserBreaches))
    }
}
