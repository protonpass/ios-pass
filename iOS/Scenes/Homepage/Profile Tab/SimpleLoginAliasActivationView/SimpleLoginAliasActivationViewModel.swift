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

    @LazyInjected(\SharedRepositoryContainer
        .accessRepository) private var accessRepository: any AccessRepositoryProtocol
    @LazyInjected(\SharedServiceContainer.vaultsManager) private var vaultsManager
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

    func activateSync() async throws {
        do {
            let userId = try await userManager.getActiveUserId()
            try await aliasRepository.enableSlAliasSync(userId: userId,
                                                        defaultShareID: selectedVault?.vault.shareId)
        } catch {
            logger.error(error)
            router.display(element: .displayErrorBanner(error))
            throw error
        }
//        Task { [weak self] in
//            guard let self else {
//                return
//            }
//
//        }
    }
}

private extension SimpleLoginAliasActivationViewModel {
    func setUp() {
        Task {
            userAliasSyncData = try? await accessRepository.getAccess().access.userData
            vaults = vaultsManager.getAllEditableVaultContents().map { .init(vaultContent: $0) }
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

//    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
//    private let logger = resolve(\SharedToolingContainer.logger)
//    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
//    private let getMainVault = resolve(\SharedUseCasesContainer.getMainVault)
//    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
//
//    let allVaults: [VaultListUiModel]
//
//    @Published private(set) var selectedVault: Vault?
//    @Published private(set) var isFreeUser = false
//
//    init() {
//        allVaults = vaultsManager.getAllEditableVaultContents().map { .init(vaultContent: $0) }
//        selectedVault = vaultsManager.vaultSelection.preciseVault
//
//        setup()
//    }
