//
//
// SimpleLoginAliasActivationViewModel.swift
// Proton Pass - Created on 05/08/2024.
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
import Combine
import Core
import Entities
import Factory
import Macro
import ProtonCoreLogin
import ProtonCoreServices
import Screens
import SwiftUI
import UseCases

@MainActor
final class SimpleLoginAliasActivationViewModel: ObservableObject, Sendable {
    @Published var selectedVault: VaultListUiModel?
    @Published private(set) var vaults: [VaultListUiModel] = []

    @Published private(set) var loading = false

    @LazyInjected(\SharedRepositoryContainer.accessRepository)
    private var accessRepository: any AccessRepositoryProtocol
    @LazyInjected(\SharedServiceContainer.appContentManager) private var appContentManager
    @LazyInjected(\SharedUseCasesContainer.getMainVault) private var getMainVault
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    private var userAliasSyncData: UserAliasSyncData?

    var canActiveSync: Bool {
        selectedVault != nil
    }

    init() {
        setUp()
    }

    func activateSync() async -> Bool {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            try await aliasRepository.enableSlAliasSync(userId: userId,
                                                        defaultShareID: selectedVault?.vault.shareId)
            try await accessRepository.refreshAccess(userId: userId)
            return true
        } catch {
            logger.error(error)
            router.display(element: .displayErrorBanner(error))
            return false
        }
    }
}

private extension SimpleLoginAliasActivationViewModel {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }
            userAliasSyncData = try? await accessRepository.getAccess(userId: nil).access.userData
            vaults = appContentManager.getAllEditableVaultContents().map { .init(vaultContent: $0) }
            if let userAliasSyncData, let shareId = userAliasSyncData.defaultShareID {
                guard let selectedVault = vaults.first(where: { $0.vault.shareId == shareId }) else {
                    let mainVault = await getMainVault()
                    self.selectedVault = vaults.first(where: { $0.vault.shareId == mainVault?.shareId })
                    return
                }
                self.selectedVault = selectedVault
            }
        }
    }
}
