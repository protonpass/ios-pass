//
//
// GetVaultInfos.swift
// Proton Pass - Created on 08/09/2023.
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
import Combine
import Entities

public protocol GetVaultInfosUseCase: Sendable {
    func execute(for id: String) -> AnyPublisher<Vault?, Never>
}

public extension GetVaultInfosUseCase {
    func callAsFunction(for id: String) -> AnyPublisher<Vault?, Never> {
        execute(for: id)
    }
}

public final class GetVaultInfos: GetVaultInfosUseCase {
    private let vaultsManager: VaultsManagerProtocol

    public init(vaultsManager: VaultsManagerProtocol) {
        self.vaultsManager = vaultsManager
    }

    public func execute(for id: String) -> AnyPublisher<Vault?, Never> {
        vaultsManager.currentVaults
            .map { $0.first(where: { $0.shareId == id }) }
            .eraseToAnyPublisher()
    }
}
