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
    func createEditItemViewModelDidTrashItem(_ type: ItemContentType)
}

enum ItemMode {
    case create(shareId: String, alias: Bool)
    case edit(ItemContent)

    var isEditMode: Bool {
        switch self {
        case .edit:
            return true
        default:
            return false
        }
    }

    var isCreateMode: Bool { !isEditMode }
}

class BaseCreateEditItemViewModel: BaseViewModel {
    @Published private(set) var isTrashed = false
    @Published var isObsolete = false
    let shareId: String
    let mode: ItemMode
    let itemRepository: ItemRepositoryProtocol

    weak var createEditItemDelegate: CreateEditItemViewModelDelegate?

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol) {
        switch mode {
        case .create(let shareId, _):
            self.shareId = shareId
        case .edit(let itemContent):
            self.shareId = itemContent.shareId
        }
        self.mode = mode
        self.itemRepository = itemRepository
        super.init()
        bindValues()
    }

    /// To be overridden by subclasses
    var isSaveable: Bool { false }

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

    func trash() {
        guard case .edit(let itemContent) = mode else { return }
        Task { @MainActor in
            defer { isLoading = false }
            do {
                isLoading = true
                let item = try await getItemTask(shareId: itemContent.shareId,
                                                 itemId: itemContent.itemId).value
                try await trashItemTask(item: item).value
                isTrashed = true
                createEditItemDelegate?.createEditItemViewModelDidTrashItem(itemContentType())
            } catch {
                self.error = error
            }
        }
    }

    private func createItem(shareId: String) {
        Task { @MainActor in
            do {
                isLoading = true
                try await createItemTask(shareId: shareId).value
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
                try await createAliasItemTask(shareId: shareId, info: info).value
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
                let shareId = oldItemContent.shareId
                let itemId = oldItemContent.itemId
                isLoading = true
                try await additionalEdit()
                guard let oldItem = try await itemRepository.getItemTask(shareId: shareId,
                                                                         itemId: itemId).value else {
                    isLoading = false
                    return
                }
                let newItemContentProtobuf = generateItemContent()
                try await updateItemTask(oldItem: oldItem.item,
                                         newItemContent: newItemContentProtobuf,
                                         shareId: shareId).value
                isLoading = false
                createEditItemDelegate?.createEditItemViewModelDidUpdateItem(itemContentType())
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }
}

// MARK: - Private supporting tasks
private extension BaseCreateEditItemViewModel {
    func createItemTask(shareId: String) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.itemRepository.createItem(itemContent: self.generateItemContent(),
                                                     shareId: shareId)
        }
    }

    func createAliasItemTask(shareId: String, info: AliasCreationInfo) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.itemRepository.createAlias(info: info,
                                                      itemContent: self.generateItemContent(),
                                                      shareId: shareId)
        }
    }

    func updateItemTask(oldItem: ItemRevision,
                        newItemContent: ProtobufableItemContentProtocol,
                        shareId: String) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.itemRepository.updateItem(oldItem: oldItem,
                                                     newItemContent: newItemContent,
                                                     shareId: shareId)
        }
    }

    func getItemTask(shareId: String, itemId: String) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) {
            guard let item = try await self.itemRepository.getItem(shareId: shareId,
                                                                   itemId: itemId) else {
                throw ItemDetailViewModelError.itemNotFound(shareId: shareId, itemId: itemId)
            }
            return item
        }
    }

    func trashItemTask(item: SymmetricallyEncryptedItem) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.itemRepository.trashItems([item])
        }
    }
}

extension BaseCreateEditItemViewModel {
    /// Refresh the item to detect changes.
    /// When changes happen, announce via `isObsolete` boolean  so the view can act accordingly
    func refresh() {
        guard case .edit(let itemContent) = mode else { return }
        Task { @MainActor in
            guard let updatedItem =
                    try await itemRepository.getItem(shareId: itemContent.shareId,
                                                     itemId: itemContent.itemId) else {
                return
            }
            isObsolete = itemContent.revision != updatedItem.item.revision
        }
    }
}
