//
//
// GetVaultItemCount.swift
// Proton Pass - Created on 20/07/2023.
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

public protocol GetVaultItemCountUseCase: Sendable {
    func execute(for vault: Share, and type: ItemContentType?) -> Int
}

public extension GetVaultItemCountUseCase {
    func callAsFunction(for vault: Share, and type: ItemContentType? = nil) -> Int {
        execute(for: vault, and: type)
    }
}

public final class GetVaultItemCount: @unchecked Sendable, GetVaultItemCountUseCase {
    private let vaultsManager: any VaultsManagerProtocol

    public init(vaultsManager: any VaultsManagerProtocol) {
        self.vaultsManager = vaultsManager
    }

    public func execute(for vault: Share, and type: ItemContentType?) -> Int {
        if let type {
            return vaultsManager.getItems(for: vault).filter { $0.type == type }.count
        }
        return vaultsManager.getItems(for: vault).count
    }
}
