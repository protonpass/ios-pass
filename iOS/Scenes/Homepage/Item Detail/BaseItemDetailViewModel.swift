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
import UIKit

let kItemDetailSectionPadding: CGFloat = 16

protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToShowSpinner()
    func itemDetailViewModelWantsToHideSpinner()
    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool)
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String)
    func itemDetailViewModelWantsToShowFullScreen(_ text: String)
    func itemDetailViewModelWantsToOpen(urlString: String)
    func itemDetailViewModelWantsToMove(item: ItemIdentifiable, delegate: MoveVaultListViewModelDelegate)
    func itemDetailViewModelWantsToUpgrade()
    func itemDetailViewModelDidMove(item: ItemTypeIdentifiable, to vault: Vault)
    func itemDetailViewModelDidMoveToTrash(item: ItemTypeIdentifiable)
    func itemDetailViewModelDidRestore(item: ItemTypeIdentifiable)
    func itemDetailViewModelDidPermanentlyDelete(item: ItemTypeIdentifiable)
    func itemDetailViewModelDidEncounter(error: Error)
}

class BaseItemDetailViewModel {
    @Published private(set) var isFreeUser = false

    let isShownAsSheet: Bool
    let itemRepository: ItemRepositoryProtocol
    let upgradeChecker: UpgradeCheckerProtocol
    private(set) var itemContent: ItemContent {
        didSet {
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }
    }

    private(set) var customFieldUiModels: [CustomFieldUiModel]
    let vault: Vault? // Nullable because we only show vault when there're more than 1 vault
    let logger: Logger
    let logManager: LogManagerProtocol
    let theme: Theme

    weak var delegate: ItemDetailViewModelDelegate?

    private var symmetricKey: SymmetricKey { itemRepository.symmetricKey }

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         itemRepository: ItemRepositoryProtocol,
         upgradeChecker: UpgradeCheckerProtocol,
         vault: Vault?,
         logManager: LogManagerProtocol,
         theme: Theme) {
        self.isShownAsSheet = isShownAsSheet
        self.itemContent = itemContent
        customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        self.itemRepository = itemRepository
        self.upgradeChecker = upgradeChecker
        self.vault = vault
        logger = .init(manager: logManager)
        self.logManager = logManager
        self.theme = theme
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
        Task { @MainActor in
            guard let updatedItemContent =
                try await itemRepository.getItemContent(shareId: itemContent.shareId,
                                                        itemId: itemContent.item.itemID) else {
                return
            }
            itemContent = updatedItemContent
            bindValues()
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
        Task { @MainActor in
            defer { delegate?.itemDetailViewModelWantsToHideSpinner() }
            do {
                logger.trace("Trashing \(itemContent.debugInformation)")
                delegate?.itemDetailViewModelWantsToShowSpinner()
                let encryptedItem = try await getItemTask(item: itemContent).value
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await itemRepository.trashItems([encryptedItem])
                delegate?.itemDetailViewModelDidMoveToTrash(item: item)
                logger.info("Trashed \(item.debugInformation)")
            } catch {
                logger.error(error)
                delegate?.itemDetailViewModelDidEncounter(error: error)
            }
        }
    }

    func restore() {
        Task { @MainActor in
            defer { delegate?.itemDetailViewModelWantsToHideSpinner() }
            do {
                logger.trace("Restoring \(itemContent.debugInformation)")
                delegate?.itemDetailViewModelWantsToShowSpinner()
                let encryptedItem = try await getItemTask(item: itemContent).value
                let symmetricKey = itemRepository.symmetricKey
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await itemRepository.untrashItems([encryptedItem])
                delegate?.itemDetailViewModelDidRestore(item: item)
                logger.info("Restored \(item.debugInformation)")
            } catch {
                logger.error(error)
                delegate?.itemDetailViewModelDidEncounter(error: error)
            }
        }
    }

    func permanentlyDelete() {
        Task { @MainActor in
            defer { delegate?.itemDetailViewModelWantsToHideSpinner() }
            do {
                logger.trace("Permanently deleting \(itemContent.debugInformation)")
                delegate?.itemDetailViewModelWantsToShowSpinner()
                let encryptedItem = try await getItemTask(item: itemContent).value
                let symmetricKey = itemRepository.symmetricKey
                let item = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                try await itemRepository.deleteItems([encryptedItem], skipTrash: false)
                delegate?.itemDetailViewModelDidPermanentlyDelete(item: item)
                logger.info("Permanently deleted \(item.debugInformation)")
            } catch {
                logger.error(error)
                delegate?.itemDetailViewModelDidEncounter(error: error)
            }
        }
    }

    func upgrade() {
        delegate?.itemDetailViewModelWantsToUpgrade()
    }
}

// MARK: - Private APIs

private extension BaseItemDetailViewModel {
    func checkIfFreeUser() {
        Task { @MainActor in
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                logger.error(error)
                delegate?.itemDetailViewModelDidEncounter(error: error)
            }
        }
    }

    func getItemTask(item: ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) {
            guard let item = try await self.itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
                throw PPError.itemNotFound(shareID: item.shareId, itemID: item.itemId)
            }
            return item
        }
    }

    func doMove(to vault: Vault) {
        Task { @MainActor in
            defer { delegate?.itemDetailViewModelWantsToHideSpinner() }
            do {
                logger.trace("Moving \(itemContent.debugInformation) to share \(vault.shareId)")
                delegate?.itemDetailViewModelWantsToShowSpinner()
                try await itemRepository.move(item: itemContent, toShareId: vault.shareId)
                logger.trace("Moved \(itemContent.debugInformation) to share \(vault.shareId)")
                delegate?.itemDetailViewModelDidMove(item: itemContent, to: vault)
            } catch {
                logger.error(error)
                delegate?.itemDetailViewModelDidEncounter(error: error)
            }
        }
    }
}

// MARK: - MoveVaultListViewModelDelegate

extension BaseItemDetailViewModel: MoveVaultListViewModelDelegate {
    func moveVaultListViewModelWantsToUpgrade() {
        delegate?.itemDetailViewModelWantsToUpgrade()
    }

    func moveVaultListViewModelDidPick(vault: Vault) {
        doMove(to: vault)
    }

    func moveVaultListViewModelDidEncounter(error: Error) {
        delegate?.itemDetailViewModelDidEncounter(error: error)
    }
}
