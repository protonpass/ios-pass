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
    func createEditItemViewModelWantsToAddCustomField(delegate: CustomFieldAdditionDelegate)
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
}

class BaseCreateEditItemViewModel {
    @Published private(set) var vault: Vault
    @Published private(set) var isSaving = false
    @Published var customFields = [CustomField]()
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

    func additionalEdit() async throws {}

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }
    func generateAliasItemContent() -> ItemContentProtobuf? { nil }

    func addCustomField() {
        delegate?.createEditItemViewModelWantsToAddCustomField(delegate: self)
    }

    func save() {
        Task { @MainActor in
            defer { isSaving = false }
            isSaving = true

            do {
                switch mode {
                case let .create(_, type):
                    logger.trace("Creating item")
                    if let createdItem = try await createItem(for: type) {
                        logger.info("Created \(createdItem.debugInformation)")
                        delegate?.createEditItemViewModelDidCreateItem(createdItem, type: itemContentType())
                    }

                case .edit(let oldItemContent):
                    logger.trace("Editing \(oldItemContent.debugInformation)")
                    try await editItem(oldItemContent: oldItemContent)
                    logger.info("Edited \(oldItemContent.debugInformation)")
                    delegate?.createEditItemViewModelDidUpdateItem(itemContentType())
                }
            } catch {
                logger.error(error)
                delegate?.createEditItemViewModelDidFail(error)
            }
        }
    }

    private func createItem(for type: ItemCreationType) async throws -> SymmetricallyEncryptedItem? {
        let shareId = vault.shareId
        let itemContent = generateItemContent()

        switch type {
        case .alias:
            if let aliasCreationInfo = generateAliasCreationInfo() {
                return try await itemRepository.createAlias(info: aliasCreationInfo,
                                                            itemContent: itemContent,
                                                            shareId: shareId)
            } else {
                assertionFailure("aliasCreationInfo should not be null")
                logger.warning("Can not create alias because creation info is empty")
                return nil
            }

        case .login:
            if let aliasCreationInfo = generateAliasCreationInfo(),
               let aliasItemContent = generateAliasItemContent() {
                let (_, createdLoginItem) = try await itemRepository.createAliasAndOtherItem(
                    info: aliasCreationInfo,
                    aliasItemContent: aliasItemContent,
                    otherItemContent: itemContent,
                    shareId: shareId)
                return createdLoginItem
            }

        default:
            break
        }

        return try await itemRepository.createItem(itemContent: itemContent, shareId: shareId)
    }

    private func editItem(oldItemContent: ItemContent) async throws {
        try await additionalEdit()
        let itemId = oldItemContent.itemId
        let shareId = oldItemContent.shareId
        guard let oldItem = try await itemRepository.getItem(shareId: shareId,
                                                             itemId: itemId) else {
            throw PPError.itemNotFound(shareID: shareId, itemID: itemId)
        }
        let newItemContent = generateItemContent()
        try await itemRepository.updateItem(oldItem: oldItem.item,
                                            newItemContent: newItemContent,
                                            shareId: oldItem.shareId)
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

// MARK: - CustomFieldTitleAlertHandlerDelegate
extension BaseCreateEditItemViewModel: CustomFieldAdditionDelegate {
    func customFieldAdded(_ customField: CustomField) {
        customFields.append(customField)
    }
}
