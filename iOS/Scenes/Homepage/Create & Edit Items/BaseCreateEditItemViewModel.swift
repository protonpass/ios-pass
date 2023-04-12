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
import Combine
import Core
import ProtonCore_Login

protocol CreateEditItemViewModelDelegate: AnyObject {
    func createEditItemViewModelWantsToShowLoadingHud()
    func createEditItemViewModelWantsToHideLoadingHud()
    func createEditItemViewModelWantsToChangeVault(selectedVault: Vault,
                                                   delegate: VaultSelectorViewModelDelegate)
    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType)
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType)
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
    case alias
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
    @Published private(set) var vault: Vault
    @Published private(set) var isSaving = false
    @Published var isObsolete = false

    let mode: ItemMode
    let itemRepository: ItemRepositoryProtocol
    let preferences: Preferences
    let logger: Logger

    var didEditSomething = false

    weak var delegate: CreateEditItemViewModelDelegate?
    var cancellables = Set<AnyCancellable>()

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol,
         vaults: [Vault],
         preferences: Preferences,
         logManager: LogManager) throws {
        let vaultShareId: String
        switch mode {
        case .create(let shareId, _):
            vaultShareId = shareId
        case .edit(let itemContent):
            vaultShareId = itemContent.shareId
        }

        guard let vault = vaults.first(where: { $0.shareId == vaultShareId }) else {
            throw PPError.vault(.vaultNotFound(vaultShareId))
        }
        self.vault = vault
        self.mode = mode
        self.itemRepository = itemRepository
        self.preferences = preferences
        self.logger = .init(manager: logManager)
        self.bindValues()
    }

    /// To be overridden by subclasses
    var isSaveable: Bool { false }

    func bindValues() {}

    // swiftlint:disable:next unavailable_function
    func itemContentType() -> ItemContentType {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func generateItemContent() -> ItemContentProtobuf {
        fatalError("Must be overridden by subclasses")
    }

    func saveButtonTitle() -> String {
        switch mode {
        case .create:
            return "Create"
        case .edit:
            return "Save"
        }
    }

    func additionalCreate() async throws {}

    func additionalEdit() async throws {}

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }

    @MainActor
    func save() async {
        switch mode {
        case let .create(_, type):
            if type.isAlias {
                await createAliasItem()
            } else {
                await createItem()
            }

        case .edit(let oldItemContent):
            await editItem(oldItemContent: oldItemContent)
        }
    }

    @MainActor
    private func createItem() async {
        defer { isSaving = false }
        do {
            isSaving = true
            try await additionalCreate()
            let item = try await createItemTask(shareId: vault.shareId).value
            delegate?.createEditItemViewModelDidCreateItem(item, type: itemContentType())
            logger.info("Created \(item.debugInformation)")
        } catch {
            logger.error(error)
            delegate?.createEditItemViewModelDidFail(error)
        }
    }

    @MainActor
    private func createAliasItem() async {
        guard let info = generateAliasCreationInfo() else { return }
        defer { isSaving = false }
        do {
            isSaving = true
            let item = try await createAliasItemTask(shareId: vault.shareId, info: info).value
            delegate?.createEditItemViewModelDidCreateItem(item, type: itemContentType())
            logger.info("Created alias item \(item.debugInformation)")
        } catch {
            logger.error(error)
            delegate?.createEditItemViewModelDidFail(error)
        }
    }

    @MainActor
    private func editItem(oldItemContent: ItemContent) async {
        defer { isSaving = false }
        do {
            isSaving = true
            try await additionalEdit()
            let oldItem = try await getItemTask(item: oldItemContent).value
            let newItemContentProtobuf = generateItemContent()
            try await updateItemTask(oldItem: oldItem.item,
                                     newItemContent: newItemContentProtobuf,
                                     shareId: oldItemContent.shareId).value
            delegate?.createEditItemViewModelDidUpdateItem(itemContentType())
            logger.info("Edited \(oldItem.debugInformation)")
        } catch {
            logger.error(error)
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

    func getItemTask(item: ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) {
            guard let item = try await self.itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
                throw PPError.itemNotFound(shareID: item.shareId, itemID: item.itemId)
            }
            return item
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

    func changeVault() {
        delegate?.createEditItemViewModelWantsToChangeVault(selectedVault: vault, delegate: self)
    }
}

// MARK: - VaultSelectorViewModelDelegate
extension BaseCreateEditItemViewModel: VaultSelectorViewModelDelegate {
    func vaultSelectorViewModelDidSelect(vault: Vault) {
        self.vault = vault
    }
}
