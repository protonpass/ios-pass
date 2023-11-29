//
//
// GetCurrentSelectedShareId.swift
// Proton Pass - Created on 04/10/2023.
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

public protocol GetCurrentSelectedShareIdUseCase: Sendable {
    func execute() async -> String?
}

public extension GetCurrentSelectedShareIdUseCase {
    func callAsFunction() async -> String? {
        await execute()
    }
}

public final class GetCurrentSelectedShareId: GetCurrentSelectedShareIdUseCase {
    private let vaultsManager: any VaultsManagerProtocol
    private let getMainVault: any GetMainVaultUseCase

    public init(vaultsManager: any VaultsManagerProtocol,
                getMainVault: any GetMainVaultUseCase) {
        self.vaultsManager = vaultsManager
        self.getMainVault = getMainVault
    }

    public func execute() async -> String? {
        switch vaultsManager.vaultSelection {
        case .all, .trash:
            await getMainVault()?.shareId
        case let .precise(vault):
            vault.shareId
        }
    }
}
