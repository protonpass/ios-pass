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
import Combine
import Core
import ProtonCore_Login
import ProtonCore_Services

protocol LoadVaultsViewModelDelegate: AnyObject {
    func loadVaultsViewModelWantsToToggleSideBar()
}

final class LoadVaultsViewModel: DeinitPrintable, ObservableObject {
    @Published private(set) var error: Error?

    deinit { print(deinitMessage) }

    private let userData: UserData
    private let apiService: APIService
    private let vaultSelection: VaultSelection
    private let repository: RepositoryProtocol

    weak var delegate: LoadVaultsViewModelDelegate?

    init(userData: UserData,
         apiService: APIService,
         vaultSelection: VaultSelection,
         repository: RepositoryProtocol) {
        self.userData = userData
        self.apiService = apiService
        self.vaultSelection = vaultSelection
        self.repository = repository
    }

    func toggleSidebarAction() {
        delegate?.loadVaultsViewModelWantsToToggleSideBar()
    }

    func fetchVaults(forceUpdate: Bool = false) {
        error = nil
        Task { @MainActor in
            do {
                let shares = try await repository.getShares(forceUpdate: forceUpdate)

                var vaults: [VaultProtocol] = []
                for share in shares {
                    let shareKey = try await repository.getShareKey(forceUpdate: forceUpdate,
                                                                    shareId: share.shareID,
                                                                    page: 0,
                                                                    pageSize: Int.max)
                    vaults.append(try share.getVault(userData: userData,
                                                     vaultKeys: shareKey.vaultKeys))
                }

                if vaults.isEmpty {
                    createDefaultVault()
                } else {
                    vaultSelection.update(vaults: vaults)
                }
            } catch {
                self.error = error
            }
        }
    }

    private func createDefaultVault() {
        Task { @MainActor in
            do {
                let createVaultEndpoint = try CreateVaultEndpoint(credential: userData.credential,
                                                                  addressKey: userData.getAddressKey(),
                                                                  name: "Personal",
                                                                  note: "Personal vault")
                _ = try await apiService.exec(endpoint: createVaultEndpoint)
                self.fetchVaults()
            } catch {
                self.error = error
            }
        }
    }
}
