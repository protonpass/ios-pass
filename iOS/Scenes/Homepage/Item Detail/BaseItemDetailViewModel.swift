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
import CryptoKit
import Entities
import Factory
import Macro
import UIKit

@MainActor
protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool)
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String)
    func itemDetailViewModelWantsToShowFullScreen(_ data: FullScreenData)
    func itemDetailViewModelDidMoveToTrash(item: any ItemTypeIdentifiable)
}

@MainActor
class BaseItemDetailViewModel: ObservableObject {
    @Published private(set) var isFreeUser = false
    @Published var moreInfoSectionExpanded = false
    @Published var showingDeleteAlert = false
    @Published private(set) var plan: Plan?

    let isShownAsSheet: Bool
    let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)

    let upgradeChecker: UpgradeCheckerProtocol
    private(set) var itemContent: ItemContent {
        didSet {
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }
    }

    private(set) var customFieldUiModels: [CustomFieldUiModel]
    let vault: VaultListUiModel?
    let shouldShowVault: Bool
    let logger = resolve(\SharedToolingContainer.logger)
    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let getUserShareStatus = resolve(\UseCasesContainer.getUserShareStatus)
    private let canUserPerformActionOnVault = resolve(\UseCasesContainer.canUserPerformActionOnVault)
    private let pinItem = resolve(\SharedUseCasesContainer.pinItem)
    private let unpinItem = resolve(\SharedUseCasesContainer.unpinItem)
    private let getFeatureFlagStatus = resolve(\SharedUseCasesContainer.getFeatureFlagStatus)
    private let getUserPlan = resolve(\SharedUseCasesContainer.getUserPlan)
    private var cancellable = Set<AnyCancellable>()

    @LazyInjected(\SharedServiceContainer.clipboardManager) private var clipboardManager

    var isAllowedToShare: Bool {
        guard let vault else {
            return false
        }
        return getUserShareStatus(for: vault.vault) != .cantShare
    }

    var isAllowedToEdit: Bool {
        guard let vault else {
            return false
        }
        return canUserPerformActionOnVault(for: vault.vault)
    }

    var itemHistoryEnabled: Bool {
        guard getFeatureFlagStatus(with: FeatureFlagType.passItemHistoryV1), let plan, !plan.isFreeUser else {
            return false
        }
        return true
    }

    weak var delegate: ItemDetailViewModelDelegate?

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         upgradeChecker: UpgradeCheckerProtocol) {
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

        getUserPlan()
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [weak self] refreshedPlan in
                guard let self else {
                    return
                }
                plan = refreshedPlan
            }.store(in: &cancellable)
    }

    /// To be overidden by subclasses
    func bindValues() {}

    /// Copy to clipboard and trigger a toast message
    /// - Parameters:
    ///    - text: The text to be copied to clipboard.
    ///    - message: The message of the toast (e.g. "Note copied", "Alias copied")
    func copyToClipboard(text: String, message: String) {
        delegate?.itemDetailViewModelWantsToCopy(text: text, bannerMessage: message)
    }

    func goBack() {
        delegate?.itemDetailViewModelWantsToGoBack(isShownAsSheet: isShownAsSheet)
    }

    func edit() {
        delegate?.itemDetailViewModelWantsToEditItem(itemContent)
    }

    func share() {
        guard let vault else { return }
        if getUserShareStatus(for: vault.vault) == .canShare {
            router.present(for: .shareVaultFromItemDetail(vault, itemContent))
        } else {
            router.present(for: .upselling)
        }
    }

    func refresh() {
        Task { @MainActor [weak self] in
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
                let newItemState = if itemContent.item.pinned {
                    try await unpinItem(item: itemContent)
                } else {
                    try await pinItem(item: itemContent)
                }
                router.display(element: .successMessage(newItemState.item.pinMessage, config: .refresh))
                logger.trace("Success of pin/unpin of \(itemContent.debugDescription)")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func copyNoteContent() {
        guard itemContent.type == .note else {
            assertionFailure("Only applicable to note item")
            return
        }
        clipboardManager.copy(text: itemContent.note,
                              bannerMessage: #localized("Note content copied"))
    }

    func moveToTrash() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Trashing \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getItemTask(item: itemContent).value
                let item = try encryptedItem.getItemContent(symmetricKey: getSymmetricKey())
                try await itemRepository.trashItems([encryptedItem])
                delegate?.itemDetailViewModelDidMoveToTrash(item: item)
                logger.info("Trashed \(item.debugDescription)")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func restore() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Restoring \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getItemTask(item: itemContent).value
                let item = try encryptedItem.getItemContent(symmetricKey: getSymmetricKey())
                try await itemRepository.untrashItems([encryptedItem])
                router.display(element: .successMessage(item.type.restoreMessage,
                                                        config: .dismissAndRefresh(with: .update(item.type))))
                logger.info("Restored \(item.debugDescription)")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func permanentlyDelete() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Permanently deleting \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getItemTask(item: itemContent).value
                let item = try encryptedItem.getItemContent(symmetricKey: getSymmetricKey())
                try await itemRepository.deleteItems([encryptedItem], skipTrash: false)
                router.display(element: .successMessage(item.type.deleteMessage,
                                                        config: .dismissAndRefresh(with: .delete(item.type))))
                logger.info("Permanently deleted \(item.debugDescription)")
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func getSymmetricKey() throws -> SymmetricKey {
        try symmetricKeyProvider.getSymmetricKey()
    }

    func showItemHistory() {
        router.present(for: .history(itemContent))
    }
}

// MARK: - Private APIs

private extension BaseItemDetailViewModel {
    func checkIfFreeUser() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func getItemTask(item: any ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, Error> {
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
}
