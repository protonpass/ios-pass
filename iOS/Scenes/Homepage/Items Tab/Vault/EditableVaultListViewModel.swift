//
// EditableVaultListViewModel.swift
// Proton Pass - Created on 08/03/2023.
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
import Combine
import Core
import Entities
import Factory
import Foundation
import Macro

private extension EditableVaultListViewModel {
    struct VaultCount: Sendable {
        let shareId: String
        let value: Int
    }

    struct Count: Sendable {
        let all: Int
        let vaultCounts: [VaultCount]
        let trashed: Int

        init(appContentManager: AppContentManager) {
            guard let sharesData = appContentManager.state.loadedContent else {
                all = 0
                vaultCounts = []
                trashed = 0
                return
            }
            var all = 0
            var vaultCounts = [VaultCount]()
            for shareContent in sharesData.shares where shareContent.share.vaultContent != nil {
                all += shareContent.itemCount
                vaultCounts.append(.init(shareId: shareContent.share.shareId, value: shareContent.itemCount))
            }
            self.all = all
            self.vaultCounts = vaultCounts
            trashed = sharesData.trashedItems.count
        }
    }
}

@MainActor
final class EditableVaultListViewModel: ObservableObject, DeinitPrintable {
    @Published private(set) var loading = false
    @Published private(set) var state = AppContentState.loading
    private let count: Count

    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let getUserShareStatus = resolve(\UseCasesContainer.getUserShareStatus)
    private let canUserPerformActionOnVault = resolve(\UseCasesContainer.canUserPerformActionOnVault)
    private let leaveShare = resolve(\UseCasesContainer.leaveShare)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var cancellables = Set<AnyCancellable>()

    var hasTrashItems: Bool {
        count.trashed > 0
    }

    var trashedAliasesCount: Int {
        guard let sharesDatas = appContentManager.state.loadedContent else {
            return 0
        }
        return sharesDatas.trashedItems.filter(\.isAlias).count
    }

    init() {
        count = .init(appContentManager: appContentManager)
        setUp()
    }

    deinit { print(deinitMessage) }

    func select(_ selection: VaultSelection) {
        appContentManager.select(selection)
    }

    func isSelected(_ selection: VaultSelection) -> Bool {
        appContentManager.isSelected(selection)
    }

    func canShare(vault: Share) -> Bool {
        getUserShareStatus(for: vault) != .cantShare && !vault.shared
    }

    func canEdit(vault: Share) -> Bool {
        canUserPerformActionOnVault(for: vault) && vault.isOwner
    }

    func canMoveItems(vault: Share) -> Bool {
        canUserPerformActionOnVault(for: vault)
    }
}

// MARK: - Private APIs

private extension EditableVaultListViewModel {
    func setUp() {
        appContentManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                state = newState
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public APIs

extension EditableVaultListViewModel {
    func delete(vault: Share) {
        guard let vaultContent = vault.vaultContent else { return }
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.delete(vault: vault)
                try await appContentManager.refresh(userId: userId)
                router.display(element: .infosMessage(#localized("Vault « %@ » deleted", vaultContent.name)))
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func createNewVault() {
        router.present(for: .vaultCreateEdit(vault: nil))
    }

    func edit(vault: Share) {
        router.present(for: .vaultCreateEdit(vault: vault))
    }

    func share(vault: Share) {
        if getUserShareStatus(for: vault) == .canShare {
            setShareInviteVault(with: .vault(vault))
            router.present(for: .sharingFlow(.none))
        } else {
            router.present(for: .upselling(.default))
        }
    }

    func leaveVault(vault: Share) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await leaveShare(userId: userId, with: vault.shareId)
                syncEventLoop.forceSync()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func restoreAllTrashedItems() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                logger.trace("Restoring all trashed items")
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.restoreAllTrashedItems(userId: userId)
                router.display(element: .successMessage(#localized("All items restored"),
                                                        config: .refresh))
                logger.info("Restored all trashed items")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func emptyTrash() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                logger.trace("Emptying all trashed items")
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await appContentManager.permanentlyDeleteAllTrashedItems(userId: userId)
                router.display(element: .infosMessage(#localized("All items permanently deleted"),
                                                      config: .refresh))
                logger.info("Emptied all trashed items")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func itemCount(for selection: VaultSelection) -> Int {
        switch selection {
        case .all:
            count.all
        case let .precise(vault):
            count.vaultCounts.first { $0.shareId == vault.shareId }?.value ?? 0
        case .trash:
            count.trashed
        }
    }
}
