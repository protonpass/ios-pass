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

protocol EditPrimaryVaultViewModelDelegate: AnyObject {
    func editPrimaryVaultViewModelWantsToShowSpinner()
    func editPrimaryVaultViewModelWantsToHideSpinner()
    func editPrimaryVaultViewModelDidUpdatePrimaryVault()
    func editPrimaryVaultViewModelDidEncounter(error: Error)
}

final class EditPrimaryVaultViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let allVaults: [VaultListUiModel]
    @Published private(set) var isLoading = false
    @Published private(set) var primaryVault: Vault

    private let shareRepository: ShareRepositoryProtocol

    weak var delegate: EditPrimaryVaultViewModelDelegate?

    init(allVaults: [VaultListUiModel],
         primaryVault: Vault,
         shareRepository: ShareRepositoryProtocol) {
        self.allVaults = allVaults
        self.primaryVault = primaryVault
        self.shareRepository = shareRepository
    }

    func setAsPrimary(vault: Vault) {
        self.primaryVault = vault
        Task { @MainActor in
            defer {
                isLoading = false
                delegate?.editPrimaryVaultViewModelWantsToHideSpinner()
            }
            do {
                isLoading = true
                delegate?.editPrimaryVaultViewModelWantsToShowSpinner()
                if try await shareRepository.setPrimaryVault(shareId: vault.shareId) {
                    delegate?.editPrimaryVaultViewModelDidUpdatePrimaryVault()
                }
            } catch {
                delegate?.editPrimaryVaultViewModelDidEncounter(error: error)
            }
        }
    }
}
