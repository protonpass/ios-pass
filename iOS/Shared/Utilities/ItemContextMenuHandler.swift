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
import Screens

@MainActor
final class ItemContextMenuHandler: Sendable {
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let pinItem = resolve(\SharedUseCasesContainer.pinItem)
    private let unpinItem = resolve(\SharedUseCasesContainer.unpinItem)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {}
}

// MARK: - Common operations

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
                Task { [weak self] in
                    guard let self else {
                        return
                    }
                    await banner.dismiss()
                    await restore(item)
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

    func viewHistory(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            router.present(for: .history(itemContent))
        }
    }
}

// MARK: - Copy functions

extension ItemContextMenuHandler {
    func copyEmail(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.loginItem?.email, message: #localized("Email copied"))
        }
    }

    func copyItemUsername(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.loginItem?.itemUsername, message: #localized("Username copied"))
        }
    }

    func copyPassword(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.loginItem?.password, message: #localized("Password copied"))
        }
    }

    func copyAlias(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.aliasEmail, message: #localized("Alias address copied"))
        }
    }

    func copyNoteContent(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.note, message: #localized("Note content copied"))
        }
    }

    func copyCardholderName(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.creditCardItem?.cardholderName, message: #localized("Cardholder name copied"))
        }
    }

    func copyCardNumber(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.creditCardItem?.number, message: #localized("Card number copied"))
        }
    }

    func copyExpirationDate(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.creditCardItem?.displayedExpirationDate,
                 message: #localized("Expiration date copied"))
        }
    }

    func copySecurityCode(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            copy(itemContent.creditCardItem?.verificationNumber, message: #localized("Security code copied"))
        }
    }
}

// MARK: - Private APIs

private extension ItemContextMenuHandler {
    func performAction(on item: any ItemTypeIdentifiable,
                       showSpinner: Bool,
                       handler: @escaping (ItemContent) async throws -> Void) {
        Task { [weak self] in
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
                if #available(iOS 17, *) {
                    ItemForceTouchTip().invalidate(reason: .actionPerformed)
                }
                try await handler(itemContent)
            } catch {
                logger.error(error)
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    /// Do not check for emptiness because the context menu options are always displayed
    /// we can't tell in advance if a field is empty or not
    /// so if we check for emptiness and do nothing, users might think it bugs when copying an empty field
    func copy(_ text: String?, message: String) {
        if let text {
            router.action(.copyToClipboard(text: text, message: message))
        }
    }
}
