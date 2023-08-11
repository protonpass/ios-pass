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
import Factory
import ProtonCore_UIFoundations

protocol ItemContextMenuHandlerDelegate: AnyObject {
    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent)
    func itemContextMenuHandlerDidTrash(item: ItemTypeIdentifiable)
    func itemContextMenuHandlerDidUntrash(item: ItemTypeIdentifiable)
    func itemContextMenuHandlerDidPermanentlyDelete(item: ItemTypeIdentifiable)
}

final class ItemContextMenuHandler {
    private let clipboardManager = resolve(\SharedServiceContainer.clipboardManager)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
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
                let itemContent = try await self.getDecryptedItemContent(for: item)
                self.delegate?.itemContextMenuHandlerWantsToEditItem(itemContent)
            } catch {
                self.handleError(error)
            }
        }
    }

    func trash(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.presentSheet(for: .hideGlobalLoading) }
            do {
                self.router.presentSheet(for: .showGlobalLoading)
                let encryptedItem = try await self.getEncryptedItem(for: item)
                try await self.itemRepository.trashItems([encryptedItem])

                let undoBlock: (PMBanner) -> Void = { [weak self] banner in
                    banner.dismiss()
                    self?.restore(item)
                }

                self.clipboardManager.bannerManager?.displayBottomInfoMessage(item.trashMessage,
                                                                              dismissButtonTitle: "Undo",
                                                                              onDismiss: undoBlock)

                self.delegate?.itemContextMenuHandlerDidTrash(item: item)
            } catch {
                self.logger.error(error)
                self.handleError(error)
            }
        }
    }

    func restore(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.presentSheet(for: .hideGlobalLoading) }
            do {
                self.router.presentSheet(for: .showGlobalLoading)
                let encryptedItem = try await self.getEncryptedItem(for: item)
                try await self.itemRepository.untrashItems([encryptedItem])
                self.clipboardManager.bannerManager?.displayBottomSuccessMessage(item.type.restoreMessage)
                self.delegate?.itemContextMenuHandlerDidUntrash(item: item)
            } catch {
                self.logger.error(error)
                self.handleError(error)
            }
        }
    }

    func deletePermanently(_ item: ItemTypeIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.presentSheet(for: .hideGlobalLoading) }
            do {
                self.router.presentSheet(for: .showGlobalLoading)
                let encryptedItem = try await self.getEncryptedItem(for: item)
                try await self.itemRepository.deleteItems([encryptedItem], skipTrash: false)
                self.clipboardManager.bannerManager?.displayBottomInfoMessage(item.type.deleteMessage)
                self.delegate?.itemContextMenuHandlerDidPermanentlyDelete(item: item)
            } catch {
                self.logger.error(error)
                self.handleError(error)
            }
        }
    }

    func copyUsername(_ item: ItemTypeIdentifiable) {
        guard case .login = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await self.getDecryptedItemContent(for: item)
                if case let .login(data) = itemContent.contentData {
                    self.clipboardManager.copy(text: data.username,
                                               bannerMessage: "Username copied")
                    self.logger.info("Copied username \(item.debugInformation)")
                }
            } catch {
                self.logger.error(error)
                self.handleError(error)
            }
        }
    }

    func copyPassword(_ item: ItemTypeIdentifiable) {
        guard case .login = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let itemContent = try await self.getDecryptedItemContent(for: item)
                if case let .login(data) = itemContent.contentData {
                    self.clipboardManager.copy(text: data.password,
                                               bannerMessage: "Password copied")
                    self.logger.info("Copied Password \(item.debugInformation)")
                }
            } catch {
                self.logger.error(error)
                self.handleError(error)
            }
        }
    }

    func copyAlias(_ item: ItemTypeIdentifiable) {
        guard case .alias = item.type else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let encryptedItem = try await self.getEncryptedItem(for: item)
                if let aliasEmail = encryptedItem.item.aliasEmail {
                    self.clipboardManager.copy(text: aliasEmail,
                                               bannerMessage: "Alias address copied")
                    self.logger.info("Copied alias address \(item.debugInformation)")
                }
            } catch {
                self.logger.error(error)
                self.handleError(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension ItemContextMenuHandler {
    func getDecryptedItemContent(for item: ItemIdentifiable) async throws -> ItemContent {
        let symmetricKey = itemRepository.symmetricKey
        let encryptedItem = try await getEncryptedItem(for: item)
        return try encryptedItem.getItemContent(symmetricKey: symmetricKey)
    }

    func getEncryptedItem(for item: ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        guard let encryptedItem = try await itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
            throw PPError.itemNotFound(shareID: item.shareId, itemID: item.itemId)
        }
        return encryptedItem
    }

    func handleError(_ error: Error) {
        clipboardManager.bannerManager?.displayTopErrorMessage(error)
    }
}
