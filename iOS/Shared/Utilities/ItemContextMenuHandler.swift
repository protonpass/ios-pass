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

protocol ItemContextMenuHandlerDelegate: AnyObject {
    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent)
}

final class ItemContextMenuHandler {
    @LazyInjected(\SharedServiceContainer.clipboardManager) private var clipboardManager
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: ItemContextMenuHandlerDelegate?

    init() {}
}

// MARK: - Public APIs

// Only show & hide spinner when trashing because API calls are needed.
// Other operations are local so no need.
extension ItemContextMenuHandler {
    func edit(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await getDecryptedItemContent(for: item)
                delegate?.itemContextMenuHandlerWantsToEditItem(itemContent)
            } catch {
                handleError(error)
            }
        }
    }

    func trash(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.trashItems([encryptedItem])

                let undoBlock: (PMBanner) -> Void = { [weak self] banner in
                    guard let self else { return }
                    banner.dismiss()
                    restore(item)
                }

                clipboardManager.bannerManager.displayBottomInfoMessage(item.trashMessage,
                                                                        dismissButtonTitle: #localized("Undo"),
                                                                        onDismiss: undoBlock)
                router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func restore(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.untrashItems([encryptedItem])
                clipboardManager.bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
                router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func deletePermanently(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.deleteItems([encryptedItem], skipTrash: false)
                clipboardManager.bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
                router.display(element: .successMessage(config: .refresh(with: .delete(item.type))))
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyUsername(_ item: ItemTypeIdentifiable) {
        guard case .login = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await getDecryptedItemContent(for: item)
                if case let .login(data) = itemContent.contentData {
                    clipboardManager.copy(text: data.username,
                                          bannerMessage: #localized("Username copied"))
                    logger.info("Copied username \(item.debugDescription)")
                }
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyPassword(_ item: ItemTypeIdentifiable) {
        guard case .login = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await getDecryptedItemContent(for: item)
                if case let .login(data) = itemContent.contentData {
                    clipboardManager.copy(text: data.password,
                                          bannerMessage: #localized("Password copied"))
                    logger.info("Copied Password \(item.debugDescription)")
                }
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyAlias(_ item: ItemTypeIdentifiable) {
        guard case .alias = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let encryptedItem = try await getEncryptedItem(for: item)
                if let aliasEmail = encryptedItem.item.aliasEmail {
                    clipboardManager.copy(text: aliasEmail,
                                          bannerMessage: #localized("Alias address copied"))
                    logger.info("Copied alias address \(item.debugDescription)")
                }
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyNoteContent(_ item: ItemTypeIdentifiable) {
        guard case .note = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await getDecryptedItemContent(for: item)
                if case .note = itemContent.contentData {
                    clipboardManager.copy(text: itemContent.note,
                                          bannerMessage: #localized("Note content copied"))
                    logger.info("Copied note content \(item.debugDescription)")
                }
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension ItemContextMenuHandler {
    func getDecryptedItemContent(for item: ItemIdentifiable) async throws -> ItemContent {
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let encryptedItem = try await getEncryptedItem(for: item)
        return try encryptedItem.getItemContent(symmetricKey: symmetricKey)
    }

    func getEncryptedItem(for item: ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        guard let encryptedItem = try await itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
            throw PassError.itemNotFound(item)
        }
        return encryptedItem
    }

    func handleError(_ error: Error) {
        clipboardManager.bannerManager.displayTopErrorMessage(error)
    }
}
