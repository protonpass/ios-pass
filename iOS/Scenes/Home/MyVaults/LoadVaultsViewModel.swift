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

    deinit {
        print(deinitMessage)
    }

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
                let getSharesEndpoint = GetSharesEndpoint(credential: coordinator.userData.credential)
                let getSharesResponse = try await coordinator.apiService.exec(endpoint: getSharesEndpoint)

                try await withThrowingTaskGroup(of: Share.self) { group in
                    for partialShare in getSharesResponse.shares {
                        let getShareDataEndpoint =
                        GetShareDataEndpoint(credential: coordinator.userData.credential,
                                             shareId: partialShare.shareID)
                        group.addTask {
                            let getShareDataResponse =
                            try await self.coordinator.apiService.exec(endpoint: getShareDataEndpoint)
                            return getShareDataResponse.share
                        }
                    }

                    var vaults: [VaultProvider] = []
                    for try await share in group {
                        vaults.append(try share.getVault(userData: self.coordinator.userData))
                    }
                    self.coordinator.vaultSelection.update(vaults: vaults)
                }
            } catch {
                self.error = error
            }
        }
    }
}
