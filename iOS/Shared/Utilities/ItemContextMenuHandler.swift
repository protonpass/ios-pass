//
// ItemContextMenuHandler.swift
// Proton Pass - Created on 19/03/2023.
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
import Core
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations

@MainActor
final class ItemContextMenuHandler: Sendable {
    @LazyInjected(\SharedServiceContainer.clipboardManager) private var clipboardManager
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let pinItem = resolve(\SharedUseCasesContainer.pinItem)
    private let unpinItem = resolve(\SharedUseCasesContainer.unpinItem)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {}
}

// MARK: - Public APIs

// Only show & hide spinner when trashing because API calls are needed.
// Other operations are local so no need.
extension ItemContextMenuHandler {
    func edit(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            router.present(for: .editItem(itemContent))
        }
    }

    func trash(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] _ in
            guard let self else { return }
            try await itemRepository.trashItems([item])

            let undoBlock: @Sendable (PMBanner) -> Void = { [weak self] banner in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }
                    banner.dismiss()
                    restore(item)
                }
            }
            bannerManager.displayBottomInfoMessage(item.trashMessage,
                                                   dismissButtonTitle: #localized("Undo"),
                                                   onDismiss: undoBlock)

            router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
        }
    }

    func restore(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] _ in
            guard let self else { return }
            try await itemRepository.untrashItems([item])
            bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
            router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
        }
    }

    func deletePermanently(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] _ in
            guard let self else { return }
            guard let encryptedItem = try await itemRepository.getItem(shareId: item.shareId,
                                                                       itemId: item.itemId) else {
                throw PassError.itemNotFound(item)
            }
            try await itemRepository.deleteItems([encryptedItem], skipTrash: false)
            bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
            router.display(element: .successMessage(config: .refresh(with: .delete(item.type))))
        }
    }

    func copyUsername(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let data = itemContent.loginItem else { return }
            clipboardManager.copy(text: data.username,
                                  bannerMessage: #localized("Username copied"))
            logger.info("Copied username \(item.debugDescription)")
        }
    }

    func copyPassword(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let data = itemContent.loginItem else { return }
            clipboardManager.copy(text: data.password,
                                  bannerMessage: #localized("Password copied"))
            logger.info("Copied Password \(item.debugDescription)")
        }
    }

    func copyAlias(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let aliasEmail = itemContent.aliasEmail else { return }
            clipboardManager.copy(text: aliasEmail,
                                  bannerMessage: #localized("Alias address copied"))
            logger.info("Copied alias address \(item.debugDescription)")
        }
    }

    func copyNoteContent(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            clipboardManager.copy(text: itemContent.note,
                                  bannerMessage: #localized("Note content copied"))
            logger.info("Copied note content \(item.debugDescription)")
        }
    }

    func copyCardholderName(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let data = itemContent.creditCardItem else { return }
            clipboardManager.copy(text: data.cardholderName,
                                  bannerMessage: #localized("Cardholder name copied"))
            logger.info("Copied cardholder name \(item.debugDescription)")
        }
    }

    func copyCardNumber(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let data = itemContent.creditCardItem else { return }
            clipboardManager.copy(text: data.number,
                                  bannerMessage: #localized("Card number copied"))
            logger.info("Copied card number \(item.debugDescription)")
        }
    }

    func copyExpirationDate(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let data = itemContent.creditCardItem else { return }
            clipboardManager.copy(text: data.expirationDate,
                                  bannerMessage: #localized("Expiration date copied"))
            logger.info("Copied expiration date \(item.debugDescription)")
        }
    }

    func copySecurityCode(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self, let data = itemContent.creditCardItem else { return }
            clipboardManager.copy(text: data.verificationNumber,
                                  bannerMessage: #localized("Security code copied"))
            logger.info("Copied security code \(item.debugDescription)")
        }
    }

    func toggleItemPinning(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] itemContent in
            guard let self else { return }
            let newItemState = if itemContent.item.pinned {
                try await unpinItem(item: itemContent)
            } else {
                try await pinItem(item: itemContent)
            }
            router.display(element: .successMessage(newItemState.item.pinMessage, config: .refresh))
            logger.trace("Success of pin/unpin of \(itemContent.debugDescription)")
        }
    }
}

// MARK: - Private APIs

private extension ItemContextMenuHandler {
    func performAction(on item: any ItemTypeIdentifiable,
                       showSpinner: Bool,
                       handler: @escaping (ItemContent) async throws -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if showSpinner {
                    router.display(element: .globalLoading(shouldShow: false))
                }
            }
            do {
                if showSpinner {
                    router.display(element: .globalLoading(shouldShow: true))
                }
                guard let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                                itemId: item.itemId) else {
                    throw PassError.itemNotFound(item)
                }
                try await handler(itemContent)
            } catch {
                logger.error(error)
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }
}
