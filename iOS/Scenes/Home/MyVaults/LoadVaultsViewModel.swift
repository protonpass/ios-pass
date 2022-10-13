//
// LoadVaultsViewModel.swift
// Proton Pass - Created on 21/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Client
import Core
import ProtonCore_Login

final class LoadVaultsViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var error: Error?

    private var actor: LoadVaultsViewModelActor!
    private let shareRepository: ShareRepositoryProtocol

    var onToggleSidebar: (() -> Void)?

    init(userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         vaultItemKeysRepository: VaultItemKeysRepositoryProtocol) {
        self.shareRepository = shareRepository
        self.actor = .init(userData: userData,
                           vaultSelection: vaultSelection,
                           shareRepository: shareRepository,
                           vaultItemKeysRepository: vaultItemKeysRepository)
    }

    func fetchVaults(forceRefresh: Bool) {
        Task { @MainActor in
            do {
                error = nil
                try await self.actor.fetchVaults(forceRefresh: forceRefresh)
            } catch {
                self.error = error
            }
        }
    }
}

private actor LoadVaultsViewModelActor {
    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let shareRepository: ShareRepositoryProtocol
    private let vaultItemKeysRepository: VaultItemKeysRepositoryProtocol

    init(userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         vaultItemKeysRepository: VaultItemKeysRepositoryProtocol) {
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.vaultItemKeysRepository = vaultItemKeysRepository
    }

    func fetchVaults(forceRefresh: Bool) async throws {
        let shares = try await shareRepository.getShares(forceRefresh: forceRefresh)

        var vaults: [VaultProtocol] = []
        for share in shares {
            let vaultKeys = try await vaultItemKeysRepository.getVaultKeys(shareId: share.shareID,
                                                                           forceRefresh: forceRefresh)
            vaults.append(try share.getVault(userData: userData,
                                             vaultKeys: vaultKeys))
        }

        if vaults.isEmpty {
            try await createDefaultVault()
            try await fetchVaults(forceRefresh: false)
        } else {
            vaultSelection.update(vaults: vaults)
        }
    }

    private func createDefaultVault() async throws {
        let addressKey = userData.getAddressKey()
        let createVaultRequest = try CreateVaultRequest(addressKey: addressKey,
                                                        name: "Personal",
                                                        description: "Personal vault")
        try await shareRepository.createVault(request: createVaultRequest)
    }
}
