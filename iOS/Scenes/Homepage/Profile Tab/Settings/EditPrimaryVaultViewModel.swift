//
// EditPrimaryVaultViewModel.swift
// Proton Pass - Created on 31/03/2023.
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

import Client
import Core
import Factory

protocol EditPrimaryVaultViewModelDelegate: AnyObject {
    func editPrimaryVaultViewModelDidUpdatePrimaryVault()
}

final class EditPrimaryVaultViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let allVaults: [VaultListUiModel]
    @Published private(set) var isLoading = false
    @Published private(set) var primaryVault: Vault

    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: EditPrimaryVaultViewModelDelegate?

    init(allVaults: [VaultListUiModel], primaryVault: Vault) {
        self.allVaults = allVaults
        self.primaryVault = primaryVault
    }

    func setAsPrimary(vault: Vault) {
        guard primaryVault.shareId != vault.shareId else {
            delegate?.editPrimaryVaultViewModelDidUpdatePrimaryVault()
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.isLoading = false
            }
            do {
                self.isLoading = true
                if try await self.shareRepository.setPrimaryVault(shareId: vault.shareId) {
                    self.primaryVault = vault
                    self.delegate?.editPrimaryVaultViewModelDidUpdatePrimaryVault()
                }
            } catch {
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
