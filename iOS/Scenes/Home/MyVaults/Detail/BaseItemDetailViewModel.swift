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
import UIKit

protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToGoBack()
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelWantsToRestore(_ item: ItemListUiModel)
    func itemDetailViewModelWantsToDisplayInformativeMessage(_ message: String)
    func itemDetailViewModelWantsToShowFullScreen(_ text: String)
    func itemDetailViewModelDidFail(_ error: Error)
}

enum ItemDetailViewModelError: Error {
    case itemNotFound(shareId: String, itemId: String)
}

class BaseItemDetailViewModel {
    private let itemRepository: ItemRepositoryProtocol
    private(set) var itemContent: ItemContent

    weak var delegate: ItemDetailViewModelDelegate?

    init(itemContent: ItemContent,
         itemRepository: ItemRepositoryProtocol) {
        self.itemContent = itemContent
        self.itemRepository = itemRepository
        self.bindValues()
    }

    /// To be overidden by subclasses
    func bindValues() {}

    /// Copy to clipboard and trigger a toast message
    /// - Parameters:
    ///    - text: The text to be copied to clipboard.
    ///    - message: The message of the toast (e.g. "Note copied", "Alias copied")
    func copyToClipboard(text: String, message: String) {
        UIPasteboard.general.string = text
        delegate?.itemDetailViewModelWantsToDisplayInformativeMessage(message)
    }

    func goBack() {
        delegate?.itemDetailViewModelWantsToGoBack()
    }

    func edit() {
        delegate?.itemDetailViewModelWantsToEditItem(itemContent)
    }

    func restore() {
        Task { @MainActor in
            do {
                if let encryptedItem = try await itemRepository.getItemTask(shareId: itemContent.shareId,
                                                                            itemId: itemContent.itemId).value {
                    let symmetricKey = itemRepository.symmetricKey
                    let item = try await encryptedItem.toItemListUiModel(symmetricKey)
                    delegate?.itemDetailViewModelWantsToRestore(item)
                }
            } catch {
                delegate?.itemDetailViewModelDidFail(error)
            }
        }
    }

    func refresh() {
        Task { @MainActor in
            guard let updatedItemContent =
                    try await itemRepository.getDecryptedItemContent(shareId: itemContent.shareId,
                                                                     itemId: itemContent.itemId) else {
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
}
