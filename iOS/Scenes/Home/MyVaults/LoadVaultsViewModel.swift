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

final class LoadVaultsViewModel: DeinitPrintable, ObservableObject {
    @Published private(set) var error: Error?

    deinit { print(deinitMessage) }

    let coordinator: MyVaultsCoordinator

    init(coordinator: MyVaultsCoordinator) {
        self.coordinator = coordinator
    }

    func toggleSidebarAction() {
        coordinator.showSidebar()
    }

    func fetchVaults() {
        error = nil
        Task { @MainActor in
            do {
                let userData = coordinator.sessionData.userData
                let apiService = coordinator.apiService

                let getSharesEndpoint = GetSharesEndpoint(credential: userData.credential)
                let getSharesResponse = try await apiService.exec(endpoint: getSharesEndpoint)

                try await withThrowingTaskGroup(of: Share.self) { [unowned self] group in
                    for partialShare in getSharesResponse.shares {
                        let getShareDataEndpoint =
                        GetShareDataEndpoint(credential: userData.credential,
                                             shareId: partialShare.shareID)
                        group.addTask {
                            let getShareDataResponse =
                            try await apiService.exec(endpoint: getShareDataEndpoint)
                            return getShareDataResponse.share
                        }
                    }

                    var vaults: [VaultProtocol] = []
                    for try await share in group {
                        let getShareKeysEndpoint = GetShareKeysEndpoint(credential: userData.credential,
                                                                        shareId: share.shareID)
                        let getShareKeysResponse = try await apiService.exec(endpoint: getShareKeysEndpoint)
                        vaults.append(try share.getVault(userData: userData,
                                                         vaultKeys: getShareKeysResponse.keys.vaultKeys))
                    }

                    if vaults.isEmpty {
                        self.createDefaultVault()
                    } else {
                        self.coordinator.vaultSelection.update(vaults: vaults)
                    }
                }
            } catch {
                self.error = error
            }
        }
    }

    private func createDefaultVault() {
        Task { @MainActor in
            do {
                let userData = coordinator.sessionData.userData
                let createVaultEndpoint = try CreateVaultEndpoint(credential: userData.credential,
                                                                  addressKey: userData.getAddressKey(),
                                                                  name: "Personal",
                                                                  note: "Personal vault")
                _ = try await coordinator.apiService.exec(endpoint: createVaultEndpoint)
                self.fetchVaults()
            } catch {
                self.error = error
            }
        }
    }
}
