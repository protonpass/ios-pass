//
// BaseItemDetailViewModel.swift
// Proton Pass - Created on 08/09/2022.
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
@preconcurrency import CryptoKit
import Entities
import Factory
import Macro
import Screens
import UIKit

@MainActor
protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool)
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelWantsToShowFullScreen(_ data: FullScreenData)
    func itemDetailViewModelDidMoveToTrash(item: any ItemTypeIdentifiable)
}

@MainActor
class BaseItemDetailViewModel: ObservableObject {
    @Published private(set) var isFreeUser = false
    @Published private(set) var isMonitored = false // Only applicable to login items
    @Published var moreInfoSectionExpanded = false
    @Published var showingDeleteAlert = false
    @Published var showingTrashAliasAlert = false

    private var superBindValuesCalled = false

    let isShownAsSheet: Bool
    let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)

    let upgradeChecker: any UpgradeCheckerProtocol
    private(set) var itemContent: ItemContent {
        didSet {
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }
    }

    private(set) var customFieldUiModels: [CustomFieldUiModel]
    let vault: VaultListUiModel?
    let shouldShowVault: Bool
    let logger = resolve(\SharedToolingContainer.logger)

    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let canUserPerformActionOnVault = resolve(\UseCasesContainer.canUserPerformActionOnVault)
    private let pinItems = resolve(\SharedUseCasesContainer.pinItems)
    private let unpinItems = resolve(\SharedUseCasesContainer.unpinItems)
    private let toggleItemMonitoring = resolve(\UseCasesContainer.toggleItemMonitoring)
    private let addItemReadEvent = resolve(\UseCasesContainer.addItemReadEvent)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private(set) var itemRepository
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private(set) var router
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) var getFeatureFlagStatus

    var isAllowedToEdit: Bool {
        guard let vault else {
            return false
        }
        return canUserPerformActionOnVault(for: vault.vault)
    }

    var aliasSyncEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passSimpleLoginAliasesSync)
    }

    weak var delegate: (any ItemDetailViewModelDelegate)?

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         upgradeChecker: any UpgradeCheckerProtocol) {
        self.isShownAsSheet = isShownAsSheet
        self.itemContent = itemContent
        customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        self.upgradeChecker = upgradeChecker

        let allVaults = vaultsManager.getAllVaultContents()
        vault = allVaults
            .first { $0.vault.shareId == itemContent.shareId }
            .map { VaultListUiModel(vaultContent: $0) }
        shouldShowVault = allVaults.count > 1

        bindValues()
        checkIfFreeUser()
        addItemReadEvent(itemContent)
        assert(superBindValuesCalled, "bindValues must be overridden with call to super")
    }

    /// To be overidden with super call by subclasses
    func bindValues() {
        isMonitored = !itemContent.item.monitoringDisabled
        superBindValuesCalled = true
    }

    /// Copy to clipboard and trigger a toast message
    /// - Parameters:
    ///    - text: The text to be copied to clipboard.
    ///    - message: The message of the toast (e.g. "Note copied", "Alias copied")
    func copyToClipboard(text: String, message: String) {
        donateToItemForceTouchTip()
        router.action(.copyToClipboard(text: text, message: message))
    }

    func goBack() {
        delegate?.itemDetailViewModelWantsToGoBack(isShownAsSheet: isShownAsSheet)
    }

    func edit() {
        donateToItemForceTouchTip()
        delegate?.itemDetailViewModelWantsToEditItem(itemContent)
    }

    func share() {
        guard let vault else { return }
        router.present(for: .shareVaultFromItemDetail(vault, itemContent))
    }

    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let shareId = itemContent.shareId
                let itemId = itemContent.item.itemID
                guard let updatedItemContent =
                    try await itemRepository.getItemContent(shareId: shareId,
                                                            itemId: itemId) else {
                    return
                }
                itemContent = updatedItemContent
                bindValues()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func showLarge(_ data: FullScreenData) {
        delegate?.itemDetailViewModelWantsToShowFullScreen(data)
    }

    func moveToAnotherVault() {
        router.present(for: .moveItemsBetweenVaults(.singleItem(itemContent)))
    }

    func toggleItemPinning() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("beginning of pin/unpin of \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                if itemContent.item.pinned {
                    try await unpinItems([itemContent])
                } else {
                    try await pinItems([itemContent])
                }
                let message = itemContent.item.pinned ?
                    #localized("Item successfully unpinned") : #localized("Item successfully pinned")
                router.display(element: .successMessage(message, config: .refresh))
                logger.trace("Success of pin/unpin of \(itemContent.debugDescription)")
                donateToItemForceTouchTip()
            } catch {
                handle(error)
            }
        }
    }

    func toggleMonitoring() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Toggling monitor from \(isMonitored) for \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                try await toggleItemMonitoring(item: itemContent, shouldNotMonitor: isMonitored)
                logger.trace("Toggled monitor to \(!isMonitored) for \(itemContent.debugDescription)")
                if isMonitored {
                    let message = #localized("Item excluded from monitoring")
                    router.display(element: .infosMessage(message))
                } else {
                    let message = #localized("Item included for monitoring")
                    router.display(element: .successMessage(message))
                }
                refresh()
            } catch {
                handle(error)
            }
        }
    }

    func copyNoteContent() {
        guard itemContent.type == .note else {
            assertionFailure("Only applicable to note item")
            return
        }
        copyToClipboard(text: itemContent.note, message: #localized("Note content copied"))
    }

    func clone() {
        router.present(for: .cloneItem(itemContent))
    }

    func moveToTrash() {
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Trashing \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getItemTask(item: itemContent).value
                let symmetricKey = try await getSymmetricKey()
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await itemRepository.trashItems([encryptedItem])
                delegate?.itemDetailViewModelDidMoveToTrash(item: item)
                logger.info("Trashed \(item.debugDescription)")
                donateToItemForceTouchTip()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func restore() {
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Restoring \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getItemTask(item: itemContent).value
                let symmetricKey = try await getSymmetricKey()
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await itemRepository.untrashItems([encryptedItem])
                router.display(element: .successMessage(item.type.restoreMessage,
                                                        config: .dismissAndRefresh(with: .update(item.type))))
                logger.info("Restored \(item.debugDescription)")
                donateToItemForceTouchTip()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func permanentlyDelete() {
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Permanently deleting \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getItemTask(item: itemContent).value
                let symmetricKey = try await getSymmetricKey()
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                let userId = try await userManager.getActiveUserId()
                try await itemRepository.deleteItems(userId: userId, [encryptedItem], skipTrash: false)
                router.display(element: .successMessage(item.type.deleteMessage,
                                                        config: .dismissAndRefresh(with: .delete(item.type))))
                logger.info("Permanently deleted \(item.debugDescription)")
                donateToItemForceTouchTip()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func getSymmetricKey() async throws -> SymmetricKey {
        try await symmetricKeyProvider.getSymmetricKey()
    }

    func showItemHistory() {
        router.present(for: .history(itemContent))
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

// MARK: - Private APIs

private extension BaseItemDetailViewModel {
    func checkIfFreeUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                handle(error)
            }
        }
    }

    func getItemTask(item: any ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, any Error> {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else {
                throw PassError.deallocatedSelf
            }
            guard let item = try await itemRepository.getItem(shareId: item.shareId,
                                                              itemId: item.itemId) else {
                throw PassError.itemNotFound(item)
            }
            return item
        }
    }

    func donateToItemForceTouchTip() {
        Task {
            guard #available(iOS 17, *) else { return }
            await ItemForceTouchTip.didPerformEligibleQuickAction.donate()
        }
    }
}
