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
protocol ItemContextMenuHandlerDelegate: AnyObject {
    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent)
}

@MainActor
final class ItemContextMenuHandler: Sendable {
    @LazyInjected(\SharedServiceContainer.clipboardManager) private var clipboardManager
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    private let pinItem = resolve(\SharedUseCasesContainer.pinItem)
    private let unpinItem = resolve(\SharedUseCasesContainer.unpinItem)

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: ItemContextMenuHandlerDelegate?

    init() {}
}

// MARK: - Public APIs

// Only show & hide spinner when trashing because API calls are needed.
// Other operations are local so no need.
extension ItemContextMenuHandler {
    func edit(_ item: any ItemTypeIdentifiable) {
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

    func trash(_ item: any ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.trashItems([encryptedItem])

                let undoBlock: @Sendable (PMBanner) -> Void = { banner in
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
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func restore(_ item: any ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.untrashItems([encryptedItem])
                bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
                router.display(element: .successMessage(config: .refresh(with: .update(item.type))))
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func deletePermanently(_ item: any ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.deleteItems([encryptedItem], skipTrash: false)
                bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
                router.display(element: .successMessage(config: .refresh(with: .delete(item.type))))
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyUsername(_ item: any ItemTypeIdentifiable) {
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

    func copyPassword(_ item: any ItemTypeIdentifiable) {
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

    func copyAlias(_ item: any ItemTypeIdentifiable) {
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

    func copyNoteContent(_ item: any ItemTypeIdentifiable) {
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

    func toggleItemPinning(_ item: any ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                let encryptedItem = try await getEncryptedItem(for: item)
                router.display(element: .globalLoading(shouldShow: true))
                let newItemState = if encryptedItem.item.pinned {
                    try await unpinItem(item: encryptedItem)
                } else {
                    try await pinItem(item: encryptedItem)
                }
                router.display(element: .successMessage(newItemState.item.pinMessage, config: .refresh))
                logger.trace("Success of pin/unpin of \(encryptedItem.debugDescription)")
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension ItemContextMenuHandler {
    func getDecryptedItemContent(for item: any ItemIdentifiable) async throws -> ItemContent {
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let encryptedItem = try await getEncryptedItem(for: item)
        return try encryptedItem.getItemContent(symmetricKey: symmetricKey)
    }

    func getEncryptedItem(for item: any ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        guard let encryptedItem = try await itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
            throw PassError.itemNotFound(item)
        }
        return encryptedItem
    }

    func handleError(_ error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}
