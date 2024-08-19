//
//
// AliasSyncConfigurationViewModel.swift
// Proton Pass - Created on 02/08/2024.
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
final class AliasSyncConfigurationViewModel: ObservableObject, Sendable {
    @Published var selectedVault: VaultListUiModel?
    @Published private(set) var vaults: [VaultListUiModel] = []

    @Published var defaultDomain: Domain?
    @Published private(set) var domains: [Domain] = []

    @Published var defaultMailbox: Mailbox?
    @Published private(set) var mailboxes: [Mailbox] = []
    @Published private(set) var userAliasSyncData: UserAliasSyncData?
    private var aliasSettings: AliasSettings?

    @Published private(set) var loading = false

    @LazyInjected(\SharedRepositoryContainer
        .accessRepository) private var accessRepository: any AccessRepositoryProtocol
    @LazyInjected(\SharedServiceContainer.vaultsManager) private var vaultsManager
    @LazyInjected(\SharedUseCasesContainer.getMainVault) private var getMainVault
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    private var selectedVaultTask: Task<Void, Never>?
    private var selectedDomainTask: Task<Void, Never>?
    private var selectedMailboxTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setUp()
    }

    func showSimpleLoginAliasesActivation() {
        router.present(for: .simpleLoginSyncActivation)
    }
}

private extension AliasSyncConfigurationViewModel {
    func setUp() {
        Task {
            defer { loading = false }
            loading = true
            do {
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

                let userId = try await userManager.getActiveUserId()
                if let userAliasSyncData, userAliasSyncData.aliasSyncEnabled {
                    aliasSettings = try await aliasRepository.getAliasSettings(userId: userId)
                }
                async let fetchDomains = try aliasRepository.getAllAliasDomains(userId: userId)
                async let fetchedMailboxes = try aliasRepository.getAllAliasMailboxes(userId: userId)
                let result = try await (fetchDomains, fetchedMailboxes)

                domains = result.0
                mailboxes = result.1
                defaultDomain = domains.first { $0.id == aliasSettings?.defaultAliasDomain } ?? domains.first
                defaultMailbox = mailboxes.first { $0.id == aliasSettings?.defaultMailboxID } ?? mailboxes.first
            } catch {
                handle(error: error)
            }
        }

        $selectedVault
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] vault in
                guard let self,
                      let userSyncData = userAliasSyncData,
                      userSyncData.aliasSyncEnabled,
                      userSyncData.defaultShareID != vault.vault.shareId else {
                    return
                }
                selectedVaultTask?.cancel()
                selectedVaultTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    await updateVaultSync()
                }
            }
            .store(in: &cancellables)

        $defaultDomain
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] domain in
                guard let self,
                      aliasSettings?.defaultAliasDomain != domain?.domain else {
                    return
                }
                selectedDomainTask?.cancel()
                selectedDomainTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    await updateDomainSync()
                }
            }
            .store(in: &cancellables)

        $defaultMailbox
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] mailbox in
                guard let self,
                      aliasSettings?.defaultMailboxID != mailbox?.mailboxID else {
                    return
                }
                selectedMailboxTask?.cancel()
                selectedMailboxTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    await updateMailboxSync()
                }
            }
            .store(in: &cancellables)
    }

    func updateVaultSync() async {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            try await aliasRepository.enableSlAliasSync(userId: userId,
                                                        defaultShareID: selectedVault?.vault.shareId)
            userAliasSyncData = try await accessRepository.getAccess().access.userData
        } catch {
            handle(error: error)
        }
    }

    func updateDomainSync() async {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            aliasSettings = try await aliasRepository
                .updateAliasDefaultDomain(userId: userId,
                                          request: UpdateAliasDomainRequest(defaultAliasDomain: defaultDomain?
                                              .domain))
        } catch {
            handle(error: error)
        }
    }

    func updateMailboxSync() async {
        guard let defaultMailbox else {
            return
        }
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            aliasSettings = try await aliasRepository
                .updateAliasDefaultMailbox(userId: userId,
                                           request: UpdateAliasMailboxRequest(defaultMailboxID: defaultMailbox
                                               .mailboxID))
        } catch {
            handle(error: error)
        }
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
