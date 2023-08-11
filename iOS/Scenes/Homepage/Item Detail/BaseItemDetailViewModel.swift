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
import Core
import CryptoKit
import Factory
import UIKit

let kItemDetailSectionPadding: CGFloat = 16

protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool)
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String)
    func itemDetailViewModelWantsToShowFullScreen(_ text: String)
    func itemDetailViewModelWantsToMove(item: ItemIdentifiable, delegate: MoveVaultListViewModelDelegate)
    func itemDetailViewModelDidMove(item: ItemTypeIdentifiable, to vault: Vault)
    func itemDetailViewModelDidMoveToTrash(item: ItemTypeIdentifiable)
    func itemDetailViewModelDidRestore(item: ItemTypeIdentifiable)
    func itemDetailViewModelDidPermanentlyDelete(item: ItemTypeIdentifiable)
}

class BaseItemDetailViewModel: ObservableObject {
    @Published private(set) var isFreeUser = false
    @Published var moreInfoSectionExpanded = false
    @Published var showingDeleteAlert = false

    let isShownAsSheet: Bool
    let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    let upgradeChecker: UpgradeCheckerProtocol
    private(set) var itemContent: ItemContent {
        didSet {
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }
    }

    private(set) var customFieldUiModels: [CustomFieldUiModel]
    let vault: Vault? // Nullable because we only show vault when there're more than 1 vault
    let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: ItemDetailViewModelDelegate?

    private var symmetricKey: SymmetricKey { itemRepository.symmetricKey }

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         upgradeChecker: UpgradeCheckerProtocol,
         vault: Vault?) {
        self.isShownAsSheet = isShownAsSheet
        self.itemContent = itemContent
        customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        self.upgradeChecker = upgradeChecker
        self.vault = vault
        bindValues()
        checkIfFreeUser()
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

    func refresh() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let shareId = self.itemContent.shareId
                let itemId = self.itemContent.item.itemID
                guard let updatedItemContent =
                    try await self.itemRepository.getItemContent(shareId: shareId,
                                                                 itemId: itemId) else {
                    return
                }
                self.itemContent = updatedItemContent
                self.bindValues()
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
            }
        }
    }

    func showLarge(_ text: String) {
        delegate?.itemDetailViewModelWantsToShowFullScreen(text)
    }

    func copyNote(_ text: String) {
        copyToClipboard(text: text, message: "Note copied")
    }

    func moveToAnotherVault() {
        delegate?.itemDetailViewModelWantsToMove(item: itemContent, delegate: self)
    }

    func moveToTrash() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.display(element: .globalLoading(shouldShow: false)) }
            do {
                self.logger.trace("Trashing \(self.itemContent.debugInformation)")
                self.router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await self.getItemTask(item: self.itemContent).value
                let item = try encryptedItem.getItemContent(symmetricKey: self.symmetricKey)
                try await self.itemRepository.trashItems([encryptedItem])
                self.delegate?.itemDetailViewModelDidMoveToTrash(item: item)
                self.logger.info("Trashed \(item.debugInformation)")
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
            }
        }
    }

    func restore() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.display(element: .globalLoading(shouldShow: false)) }
            do {
                self.logger.trace("Restoring \(self.itemContent.debugInformation)")
                self.router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await self.getItemTask(item: self.itemContent).value
                let symmetricKey = self.itemRepository.symmetricKey
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await self.itemRepository.untrashItems([encryptedItem])
                self.delegate?.itemDetailViewModelDidRestore(item: item)
                self.logger.info("Restored \(item.debugInformation)")
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
            }
        }
    }

    func permanentlyDelete() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.display(element: .globalLoading(shouldShow: false)) }
            do {
                self.logger.trace("Permanently deleting \(self.itemContent.debugInformation)")
                self.router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await self.getItemTask(item: self.itemContent).value
                let symmetricKey = self.itemRepository.symmetricKey
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await self.itemRepository.deleteItems([encryptedItem], skipTrash: false)
                self.delegate?.itemDetailViewModelDidPermanentlyDelete(item: item)
                self.logger.info("Permanently deleted \(item.debugInformation)")
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
            }
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }
}

// MARK: - Private APIs

private extension BaseItemDetailViewModel {
    func checkIfFreeUser() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.isFreeUser = try await self.upgradeChecker.isFreeUser()
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
            }
        }
    }

    func getItemTask(item: ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else {
                throw PPError.deallocatedSelf
            }
            guard let item = try await self.itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
                throw PPError.itemNotFound(shareID: item.shareId, itemID: item.itemId)
            }
            return item
        }
    }

    func doMove(to vault: Vault) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.display(element: .globalLoading(shouldShow: false)) }
            do {
                self.logger.trace("Moving \(self.itemContent.debugInformation) to share \(vault.shareId)")
                self.router.display(element: .globalLoading(shouldShow: true))
                try await self.itemRepository.move(item: self.itemContent, toShareId: vault.shareId)
                self.logger.trace("Moved \(self.itemContent.debugInformation) to share \(vault.shareId)")
                self.delegate?.itemDetailViewModelDidMove(item: itemContent, to: vault)
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
            }
        }
    }
}

// MARK: - MoveVaultListViewModelDelegate

extension BaseItemDetailViewModel: MoveVaultListViewModelDelegate {
    func moveVaultListViewModelWantsToUpgrade() {
        router.present(for: .upgradeFlow)
    }

    func moveVaultListViewModelDidPick(vault: Vault) {
        doMove(to: vault)
    }

    func moveVaultListViewModelDidEncounter(error: Error) {
        router.display(element: .displayErrorBanner(errorLocalized: error.localizedDescription))
    }
}
