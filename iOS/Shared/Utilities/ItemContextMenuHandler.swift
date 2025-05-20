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
import FactoryKit
import Macro
@preconcurrency import ProtonCoreUIFoundations
import Screens

final class ItemContextMenuHandler: @unchecked Sendable {
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedUseCasesContainer.pinItems) private var pinItems
    @LazyInjected(\SharedUseCasesContainer.unpinItems) private var unpinItems
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router

    init() {}
}

// MARK: - Common operations

extension ItemContextMenuHandler {
    func edit(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await router.present(for: .editItem(itemContent))
        }
    }

    @MainActor
    func trash(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] _ in
            guard let self else { return }
            try await itemRepository.trashItems([item])

            let undoBlock: @Sendable (PMBanner) -> Void = { [weak self] banner in
                guard let self else { return }
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

            await router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
        }
    }

    func restore(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] _ in
            guard let self else { return }
            try await itemRepository.untrashItems([item])
            bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
            await router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
        }
    }

    func deletePermanently(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] _ in
            guard let self else { return }
            guard let encryptedItem = try await itemRepository.getItem(shareId: item.shareId,
                                                                       itemId: item.itemId) else {
                throw PassError.itemNotFound(item)
            }
            let userId = try await userManager.getActiveUserId()
            try await itemRepository.deleteItems(userId: userId, [encryptedItem], skipTrash: false)
            bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
            await router.display(element: .successMessage(config: .dismissAndRefresh(with: .delete(item.type))))
        }
    }

    func toggleItemPinning(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] itemContent in
            guard let self else { return }
            if itemContent.item.pinned {
                try await unpinItems([item])
            } else {
                try await pinItems([item])
            }
            let message = itemContent.item.pinned ?
                #localized("Item successfully unpinned") : #localized("Item successfully pinned")
            await router.display(element: .successMessage(message, config: .refresh))
            logger.trace("Success of pin/unpin of \(itemContent.debugDescription)")
        }
    }

    func viewHistory(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await router.present(for: .history(itemContent))
        }
    }

    func disableAlias(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: true) { [weak self] itemContent in
            guard let self else { return }

            let userId = try await userManager.getActiveUserId()
            try await itemRepository.changeAliasStatus(userId: userId,
                                                       items: [itemContent],
                                                       enabled: false)
            await router.display(element: .infosMessage(#localized("Alias disabled"), config: .refresh))
        }
    }
}

// MARK: - Copy functions

extension ItemContextMenuHandler {
    func copyEmail(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.email, message: #localized("Email copied"))
        }
    }

    func copyItemUsername(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.loginItem?.username, message: #localized("Username copied"))
        }
    }

    func copyPassword(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.loginItem?.password, message: #localized("Password copied"))
        }
    }

    func copyAlias(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.aliasEmail, message: #localized("Alias address copied"))
        }
    }

    func toggleAliasStatus(_ item: any ItemTypeIdentifiable, enabled: Bool) {
        performAction(on: item, showSpinner: true) { [weak self] itemContent in
            guard let self else { return }
            let userId = try await userManager.getActiveUserId()
            try await itemRepository.changeAliasStatus(userId: userId,
                                                       items: [itemContent],
                                                       enabled: enabled)
            let message = enabled ? #localized("Alias enabled") : #localized("Alias disabled")
            await router.display(element: .infosMessage(message, config: .refresh))
        }
    }

    func copyNoteContent(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.note, message: #localized("Note content copied"))
        }
    }

    func copyCardholderName(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.creditCardItem?.cardholderName, message: #localized("Cardholder name copied"))
        }
    }

    func copyCardNumber(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.creditCardItem?.number, message: #localized("Card number copied"))
        }
    }

    func copyExpirationDate(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.creditCardItem?.displayedExpirationDate,
                       message: #localized("Expiration date copied"))
        }
    }

    func copySecurityCode(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.creditCardItem?.verificationNumber, message: #localized("Security code copied"))
        }
    }

    func copyFullname(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.identityItem?.fullName, message: #localized("Full name copied"))
        }
    }

    func copySsid(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.wifi?.ssid, message: #localized("SSID copied"))
        }
    }

    func copyWifiPassword(_ item: any ItemTypeIdentifiable) {
        performAction(on: item, showSpinner: false) { [weak self] itemContent in
            guard let self else { return }
            await copy(itemContent.wifi?.password, message: #localized("WiFi password copied"))
        }
    }
}

// MARK: - Private APIs

private extension ItemContextMenuHandler {
    func performAction(on item: any ItemTypeIdentifiable,
                       showSpinner: Bool,
                       handler: @Sendable @escaping (ItemContent) async throws -> Void) {
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
    @MainActor
    func copy(_ text: String?, message: String) {
        if let text {
            router.action(.copyToClipboard(text: text, message: message))
        }
    }
}
