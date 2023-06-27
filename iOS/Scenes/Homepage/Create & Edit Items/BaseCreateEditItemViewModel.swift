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
    func createEditItemViewModelWantsToEditCustomFieldTitle(_ uiModel: CustomFieldUiModel,
                                                            delegate: CustomFieldEditionDelegate)
    func createEditItemViewModelWantsToUpgrade()
    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType)
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType)
    func createEditItemViewModelDidEncounter(error: Error)
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
    @Published private(set) var selectedVault: Vault
    @Published private(set) var isFreeUser = false
    @Published private(set) var isSaving = false
    @Published private(set) var canAddMoreCustomFields = true
    @Published var customFieldUiModels = [CustomFieldUiModel]() {
        didSet {
            didEditSomething = true
        }
    }

    @Published var isObsolete = false

    let mode: ItemMode
    let itemRepository: ItemRepositoryProtocol
    let upgradeChecker: UpgradeCheckerProtocol
    let preferences: Preferences
    let logger: Logger
    let vaults: [Vault]

    var hasEmptyCustomField: Bool { customFieldUiModels.contains(where: \.customField.content.isEmpty) }
    var didEditSomething = false

    weak var delegate: CreateEditItemViewModelDelegate?
    var cancellables = Set<AnyCancellable>()

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol,
         upgradeChecker: UpgradeCheckerProtocol,
         vaults: [Vault],
         preferences: Preferences,
         logManager: LogManager) throws {
        let vaultShareId: String
        switch mode {
        case let .create(shareId, _):
            vaultShareId = shareId
        case let .edit(itemContent):
            vaultShareId = itemContent.shareId
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }

        guard let vault = vaults.first(where: { $0.shareId == vaultShareId }) ?? vaults.first else {
            throw PPError.vault(.vaultNotFound(vaultShareId))
        }
        selectedVault = vault
        self.mode = mode
        self.itemRepository = itemRepository
        self.upgradeChecker = upgradeChecker
        self.preferences = preferences
        logger = .init(manager: logManager)
        self.vaults = vaults
        bindValues()
        checkIfFreeUser()
        pickPrimaryVaultIfApplicable()
        checkIfAbleToAddMoreCustomFields()
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
}

// MARK: - Private APIs

private extension BaseCreateEditItemViewModel {
    func checkIfFreeUser() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                self.logger.error(error)
                self.delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

    /// Automatically switch to primary vault if free user. They won't be able to select other vaults anyway.
    func pickPrimaryVaultIfApplicable() {
        guard case .create = mode, vaults.count > 1, !selectedVault.isPrimary else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let isFreeUser = try await self.upgradeChecker.isFreeUser()
                if isFreeUser, let primaryVault = self.vaults.first(where: { $0.isPrimary }) {
                    self.selectedVault = primaryVault
                }
            } catch {
                self.logger.error(error)
                self.delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

    func checkIfAbleToAddMoreCustomFields() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let isFreeUser = try await self.upgradeChecker.isFreeUser()
                self.canAddMoreCustomFields = !isFreeUser
            } catch {
                self.logger.error(error)
                self.delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

    func createItem(for type: ItemCreationType) async throws -> SymmetricallyEncryptedItem? {
        let shareId = selectedVault.shareId
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
                let (_, createdLoginItem) = try await itemRepository
                    .createAliasAndOtherItem(info: aliasCreationInfo,
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

    func editItem(oldItemContent: ItemContent) async throws {
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

// MARK: - Public APIs

extension BaseCreateEditItemViewModel {
    func addCustomField() {
        delegate?.createEditItemViewModelWantsToAddCustomField(delegate: self)
    }

    func editCustomFieldTitle(_ uiModel: CustomFieldUiModel) {
        delegate?.createEditItemViewModelWantsToEditCustomFieldTitle(uiModel, delegate: self)
    }

    func upgrade() {
        delegate?.createEditItemViewModelWantsToUpgrade()
    }

    func save() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            defer { self.isSaving = false }
            self.isSaving = true

            do {
                switch self.mode {
                case let .create(_, type):
                    self.logger.trace("Creating item")
                    if let createdItem = try await self.createItem(for: type) {
                        self.logger.info("Created \(createdItem.debugInformation)")
                        self.delegate?.createEditItemViewModelDidCreateItem(createdItem, type: itemContentType())
                    }

                case let .edit(oldItemContent):
                    self.logger.trace("Editing \(oldItemContent.debugInformation)")
                    try await self.editItem(oldItemContent: oldItemContent)
                    self.logger.info("Edited \(oldItemContent.debugInformation)")
                    self.delegate?.createEditItemViewModelDidUpdateItem(itemContentType())
                }
            } catch {
                self.logger.error(error)
                self.delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

    /// Refresh the item to detect changes.
    /// When changes happen, announce via `isObsolete` boolean  so the view can act accordingly
    func refresh() {
        guard case let .edit(itemContent) = mode else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let updatedItem =
                try await self.itemRepository.getItem(shareId: itemContent.shareId,
                                                      itemId: itemContent.item.itemID) else {
                return
            }
            self.isObsolete = itemContent.item.revision != updatedItem.item.revision
        }
    }

    func changeVault() {
        delegate?.createEditItemViewModelWantsToChangeVault(selectedVault: selectedVault, delegate: self)
    }
}

// MARK: - VaultSelectorViewModelDelegate

extension BaseCreateEditItemViewModel: VaultSelectorViewModelDelegate {
    func vaultSelectorViewModelWantsToUpgrade() {
        upgrade()
    }

    func vaultSelectorViewModelDidSelect(vault: Vault) {
        selectedVault = vault
    }

    func vaultSelectorViewModelDidEncounter(error: Error) {
        delegate?.createEditItemViewModelDidEncounter(error: error)
    }
}

// MARK: - CustomFieldTitleAlertHandlerDelegate

extension BaseCreateEditItemViewModel: CustomFieldAdditionDelegate {
    func customFieldAdded(_ customField: CustomField) {
        customFieldUiModels.append(.init(customField: customField))
    }
}

// MARK: - CustomFieldEditionDelegate

extension BaseCreateEditItemViewModel: CustomFieldEditionDelegate {
    func customFieldEdited(_ uiModel: CustomFieldUiModel, newTitle: String) {
        guard let index = customFieldUiModels.firstIndex(where: { $0.id == uiModel.id }) else {
            let message = "Custom field with id \(uiModel.id) not found"
            logger.error(message)
            assertionFailure(message)
            return
        }
        customFieldUiModels[index] = .init(id: uiModel.id,
                                           customField: .init(title: newTitle,
                                                              type: uiModel.customField.type,
                                                              content: uiModel.customField.content))
    }
}
