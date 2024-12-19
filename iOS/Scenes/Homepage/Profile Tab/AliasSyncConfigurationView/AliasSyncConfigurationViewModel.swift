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
import DesignSystem
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
    @Published private(set) var pendingSyncDisabledAliases = 0
    private(set) var plan: Plan?

    @Published private(set) var loading = false
    @Published private(set) var showSyncSection = false
    @Published var error: (any Error)?

    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository
    @LazyInjected(\SharedServiceContainer.appContentManager) private var appContentManager
    @LazyInjected(\SharedUseCasesContainer.getMainVault) private var getMainVault
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    private var selectedVaultTask: Task<Void, Never>?
    private var selectedDomainTask: Task<Void, Never>?
    private var selectedMailboxTask: Task<Void, Never>?
    private var aliasSettings: AliasSettings?

    var isAdvancedAliasManagementActive: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passAdvancedAliasManagementV1)
    }

    private var cancellables = Set<AnyCancellable>()

    var canManageAliases: Bool {
        plan?.manageAlias ?? false
    }

    var shouldUpsell: Bool {
        !canManageAliases && isAdvancedAliasManagementActive
    }

    init() {
        let access = accessRepository.access.value?.access
        plan = access?.plan
        setUp()
    }

    func loadData() async {
        defer { loading = false }
        loading = true
        do {
            let userId = try await userManager.getActiveUserId()
            userAliasSyncData = try await accessRepository.getAccess(userId: userId).access.userData
            aliasSettings = try await aliasRepository.getAliasSettings(userId: userId)
            if let userAliasSyncData, userAliasSyncData.aliasSyncEnabled {
                showSyncSection = true
            } else {
                pendingSyncDisabledAliases = try await aliasRepository.getAliasSyncStatus(userId: userId)
                    .pendingAliasCount
                showSyncSection = pendingSyncDisabledAliases > 0
            }

            vaults = appContentManager.getAllEditableVaultContents().map { .init(vaultContent: $0) }
            if let userAliasSyncData, let shareId = userAliasSyncData.defaultShareID {
                if let selectedVault = vaults.first(where: { $0.vault.shareId == shareId }) {
                    self.selectedVault = selectedVault
                } else {
                    let mainVault = await getMainVault()
                    selectedVault = vaults.first { $0.vault.shareId == mainVault?.shareId }
                }
            }

            async let fetchDomains = try aliasRepository.getAllAliasDomains(userId: userId)
            async let fetchedMailboxes = try aliasRepository.getAllAliasMailboxes(userId: userId)
            let result = try await (fetchDomains, fetchedMailboxes)

            domains = result.0
            mailboxes = result.1
            defaultDomain = domains.first { $0.id == aliasSettings?.defaultAliasDomain }
            defaultMailbox = mailboxes.first { $0.id == aliasSettings?.defaultMailboxID } ?? mailboxes.first
        } catch {
            logger.error(error)
            // Record the error so at the UI level, we can let the users retry
            // instead showing the error as a banner which doesn't help resolving
            self.error = error
        }
    }

    func showSimpleLoginAliasesActivation() {
        router.present(for: .simpleLoginSyncActivation)
    }

    func setDefaultMailBox(mailbox: Mailbox) {
        guard !mailboxes.isEmpty,
              aliasSettings?.defaultMailboxID != mailbox.mailboxID else {
            return
        }
        selectedMailboxTask?.cancel()
        selectedMailboxTask = Task { [weak self] in
            guard let self else {
                return
            }
            await updateDefaultMailbox(mailbox: mailbox)
        }
    }

    func upsell() {
        let config = UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                                title: #localized("Manage your aliases"),
                                                description: UpsellEntry.aliasManagement.description,
                                                upsellElements: UpsellEntry.aliasManagement.upsellElements,
                                                ctaTitle: #localized("Get Pass Plus"))
        router.present(for: .upselling(config))
    }

    func delete(mailbox: Mailbox, transferMailboxId: Int?) {
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            router.display(element: .globalLoading(shouldShow: true))
            do {
                let userId = try await userManager.getActiveUserId()
                try await aliasRepository.deleteMailbox(userId: userId,
                                                        mailboxID: mailbox.mailboxID,
                                                        transferMailboxID: transferMailboxId)
            } catch {
                handle(error: error)
            }
        }
    }
}

private extension AliasSyncConfigurationViewModel {
    func setUp() {
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
                    await updateVault()
                }
            }
            .store(in: &cancellables)

        $defaultDomain
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] domain in
                guard let self,
                      !domains.isEmpty,
                      aliasSettings?.defaultAliasDomain != domain?.domain else {
                    return
                }
                selectedDomainTask?.cancel()
                selectedDomainTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    await updateDomain()
                }
            }
            .store(in: &cancellables)

        aliasRepository.mailboxUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case let .created(mailbox):
                    mailboxes.append(mailbox)
                case let .deleted(mailboxId):
                    mailboxes.removeAll(where: { $0.mailboxID == mailboxId })
                case let .verified(mailbox):
                    if let index = mailboxes.firstIndex(where: { $0.mailboxID == mailbox.mailboxID }) {
                        mailboxes[index] = mailbox
                    }
                }
            }
            .store(in: &cancellables)
    }

    func updateVault() async {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            try await aliasRepository.enableSlAliasSync(userId: userId,
                                                        defaultShareID: selectedVault?.vault.shareId)
            userAliasSyncData = try await accessRepository.getAccess(userId: userId).access.userData
        } catch {
            handle(error: error)
        }
    }

    func updateDomain() async {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            let request = UpdateAliasDomainRequest(defaultAliasDomain: defaultDomain?.domain)
            aliasSettings = try await aliasRepository.updateAliasDefaultDomain(userId: userId,
                                                                               request: request)
        } catch {
            handle(error: error)
        }
    }

    func updateDefaultMailbox(mailbox: Mailbox) async {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            let request = UpdateAliasMailboxRequest(defaultMailboxID: mailbox.mailboxID)
            aliasSettings = try await aliasRepository.updateAliasDefaultMailbox(userId: userId,
                                                                                request: request)
            defaultMailbox = mailbox
        } catch {
            handle(error: error)
        }
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
