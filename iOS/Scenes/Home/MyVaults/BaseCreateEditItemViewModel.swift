//
// BaseCreateEditItemViewModel.swift
// Proton Pass - Created on 19/08/2022.
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
import ProtonCore_Login

protocol CreateEditItemViewModelDelegate: AnyObject {
    func createEditItemViewModelDidCreateItem(_ type: ItemContentType)
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType)
}

enum ItemMode {
    case create(shareId: String, alias: Bool)
    case edit(ItemContent)
}

class BaseCreateEditItemViewModel: BaseViewModel {
    let shareId: String
    let mode: ItemMode
    let itemRepository: ItemRepositoryProtocol
    let credentialRepository: CredentialRepositoryProtocol

    weak var createEditItemDelegate: CreateEditItemViewModelDelegate?

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol,
         credentialRepository: CredentialRepositoryProtocol) {
        switch mode {
        case .create(let shareId, _):
            self.shareId = shareId
        case .edit(let itemContent):
            self.shareId = itemContent.shareId
        }
        self.mode = mode
        self.itemRepository = itemRepository
        self.credentialRepository = credentialRepository
        super.init()
        bindValues()
    }

    /// To be overridden by subclasses
    func bindValues() {}

    // swiftlint:disable:next unavailable_function
    func navigationBarTitle() -> String {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func itemContentType() -> ItemContentType {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func generateItemContent() -> ItemContentProtobuf {
        fatalError("Must be overridden by subclasses")
    }

    func additionalEdit() async throws {}

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }

    func save() {
        switch mode {
        case let .create(shareId, alias):
            if alias {
                createAliasItem(shareId: shareId)
            } else {
                createItem(shareId: shareId)
            }

        case .edit(let oldItemContent):
            editItem(oldItemContent: oldItemContent)
        }
    }

    private func createItem(shareId: String) {
        Task { @MainActor in
            do {
                isLoading = true
                try await itemRepository.createItem(itemContent: generateItemContent(),
                                                    shareId: shareId)
                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidCreateItem(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    private func createAliasItem(shareId: String) {
        guard let info = generateAliasCreationInfo() else { return }
        Task { @MainActor in
            do {
                isLoading = true
                try await itemRepository.createAlias(info: info,
                                                     itemContent: generateItemContent(),
                                                     shareId: shareId)
                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidCreateItem(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    private func editItem(oldItemContent: ItemContent) {
        Task { @MainActor in
            do {
                try await additionalEdit()
                let shareId = oldItemContent.shareId
                let itemId = oldItemContent.itemId
                isLoading = true
                guard let oldItem = try await itemRepository.getItem(shareId: shareId,
                                                                     itemId: itemId) else {
                    isLoading = false
                    return
                }
                let newItemContentProtobuf = generateItemContent()
                try await itemRepository.updateItem(oldItem: oldItem.item,
                                                    newItemContent: newItemContentProtobuf,
                                                    shareId: shareId)

                // Update credential database if item is login
                if itemContentType() == .login {
                    try await credentialRepository.update(oldContentData: oldItemContent.contentData,
                                                          newContentData: newItemContentProtobuf.contentData,
                                                          shareId: shareId,
                                                          itemId: itemId)
                }

                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidUpdateItem(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }
}
