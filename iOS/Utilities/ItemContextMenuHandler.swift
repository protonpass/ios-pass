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

protocol ItemContextMenuHandlerDelegate: AnyObject {
    func itemContextMenuHandlerWantsToShowSpinner()
    func itemContextMenuHandlerWantsToHideSpinner()
    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent)
    func itemContextMenuHandlerDidTrashAnItem()
}

final class ItemContextMenuHandler {
    let clipboardManager: ClipboardManager
    let itemRepository: ItemRepositoryProtocol
    let logger: Logger

    weak var delegate: ItemContextMenuHandlerDelegate?

    init(clipboardManager: ClipboardManager,
         itemRepository: ItemRepositoryProtocol,
         logManager: LogManager) {
        self.clipboardManager = clipboardManager
        self.itemRepository = itemRepository
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }
}

// MARK: - Public APIs
// Only show & hide spinner when trashing because API calls are needed.
// Other operations are local so no need.
extension ItemContextMenuHandler {
    func edit(_ item: ItemTypeIdentifiable) {
        Task { @MainActor in
            do {
                let itemContent = try await self.getDecryptedItemContent(for: item)
                delegate?.itemContextMenuHandlerWantsToEditItem(itemContent)
            } catch {
                handleError(error)
            }
        }
    }

    func trash(_ item: ItemTypeIdentifiable) {
        Task { @MainActor in
            defer { delegate?.itemContextMenuHandlerWantsToHideSpinner() }
            do {
                delegate?.itemContextMenuHandlerWantsToShowSpinner()
                let encryptedItem = try await getEncryptedItem(for: item)
                try await itemRepository.trashItems([encryptedItem])

                let message: String
                switch item.type {
                case .alias:
                    message = "Alias deleted"
                case .login:
                    message = "Login deleted"
                case .note:
                    message = "Note deleted"
                }
                clipboardManager.bannerManager?.displayBottomInfoMessage(message)

                delegate?.itemContextMenuHandlerDidTrashAnItem()
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyUsername(_ item: ItemTypeIdentifiable) {
        guard case .login = item.type else { return }
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContent(for: item)
                if case .login(let data) = itemContent.contentData {
                    clipboardManager.copy(text: data.username,
                                          bannerMessage: "Username copied")
                    logger.info("Copied username \(item.debugInformation)")
                }
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyPassword(_ item: ItemTypeIdentifiable) {
        guard case .login = item.type else { return }
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContent(for: item)
                if case .login(let data) = itemContent.contentData {
                    clipboardManager.copy(text: data.password,
                                          bannerMessage: "Password copied")
                    logger.info("Copied Password \(item.debugInformation)")
                }
            } catch {
                logger.error(error)
                handleError(error)
            }
        }
    }

    func copyAlias(_ item: ItemTypeIdentifiable) {
        guard case .alias = item.type else { return }
        Task { @MainActor in
            do {
                let encryptedItem = try await getEncryptedItem(for: item)
                if let aliasEmail = encryptedItem.item.aliasEmail {
                    clipboardManager.copy(text: aliasEmail,
                                          bannerMessage: "Alias address copied")
                    logger.info("Copied alias address \(item.debugInformation)")
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
        let symmetricKey = self.itemRepository.symmetricKey
        let encryptedItem = try await self.getEncryptedItem(for: item)
        return try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
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
