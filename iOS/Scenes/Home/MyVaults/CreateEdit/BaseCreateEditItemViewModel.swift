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
    func createEditItemViewModelWantsToShowLoadingHud()
    func createEditItemViewModelWantsToHideLoadingHud()
    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType)
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType)
    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType)
    func createEditItemViewModelDidFail(_ error: Error)
}

enum ItemMode {
    case create(shareId: String, type: ItemCreationType)
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

enum ItemCreationType {
    case alias(delegate: AliasCreationDelegate?, title: String)
    case login(title: String?, url: String?, autofill: Bool)
    case other

    var isAlias: Bool {
        switch self {
        case .alias:
            return true
        default:
            return false
        }
    }
}

class BaseCreateEditItemViewModel {
    @Published private(set) var isSaving = false
    @Published var isObsolete = false

    let shareId: String
    let mode: ItemMode
    let itemRepository: ItemRepositoryProtocol

    weak var delegate: CreateEditItemViewModelDelegate?

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
        self.bindValues()
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

    func additionalCreate() async throws {}

    func additionalEdit() async throws {}

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }

    @MainActor
    func save() async {
        switch mode {
        case let .create(shareId, type):
            if type.isAlias {
                await createAliasItem(shareId: shareId)
            } else {
                await createItem(shareId: shareId)
            }

        case .edit(let oldItemContent):
            await editItem(oldItemContent: oldItemContent)
        }
    }

    func trash() {
        guard case .edit(let itemContent) = mode else { return }
        Task { @MainActor in
            defer { delegate?.createEditItemViewModelWantsToHideLoadingHud() }
            do {
                delegate?.createEditItemViewModelWantsToShowLoadingHud()
                let item = try await getItemTask(shareId: itemContent.shareId,
                                                 itemId: itemContent.item.itemID).value
                try await trashItemTask(item: item).value
                delegate?.createEditItemViewModelDidTrashItem(item, type: itemContentType())
            } catch {
                delegate?.createEditItemViewModelDidFail(error)
            }
        }
    }

    @MainActor
    private func createItem(shareId: String) async {
        defer { isSaving = false }
        do {
            isSaving = true
            try await additionalCreate()
            let item = try await createItemTask(shareId: shareId).value
            delegate?.createEditItemViewModelDidCreateItem(item, type: itemContentType())
        } catch {
            delegate?.createEditItemViewModelDidFail(error)
        }
    }

    @MainActor
    private func createAliasItem(shareId: String) async {
        guard let info = generateAliasCreationInfo() else { return }
        defer { isSaving = false }
        do {
            isSaving = true
            let item = try await createAliasItemTask(shareId: shareId, info: info).value
            delegate?.createEditItemViewModelDidCreateItem(item, type: itemContentType())
        } catch {
            delegate?.createEditItemViewModelDidFail(error)
        }
    }

    @MainActor
    private func editItem(oldItemContent: ItemContent) async {
        defer { isSaving = false }
        do {
            let shareId = oldItemContent.shareId
            let itemId = oldItemContent.item.itemID
            isSaving = true
            try await additionalEdit()
            guard let oldItem = try await itemRepository.getItemTask(shareId: shareId,
                                                                     itemId: itemId).value else {
                return
            }
            let newItemContentProtobuf = generateItemContent()
            try await updateItemTask(oldItem: oldItem.item,
                                     newItemContent: newItemContentProtobuf,
                                     shareId: shareId).value
            delegate?.createEditItemViewModelDidUpdateItem(itemContentType())
        } catch {
            delegate?.createEditItemViewModelDidFail(error)
        }
    }
}

// MARK: - Private supporting tasks
private extension BaseCreateEditItemViewModel {
    func createItemTask(shareId: String) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.itemRepository.createItem(itemContent: self.generateItemContent(),
                                                     shareId: shareId)
        }
    }

    func createAliasItemTask(shareId: String, info: AliasCreationInfo) -> Task<SymmetricallyEncryptedItem, Error> {
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
                                                     itemId: itemContent.item.itemID) else {
                return
            }
            isObsolete = itemContent.item.revision != updatedItem.item.revision
        }
    }
}
