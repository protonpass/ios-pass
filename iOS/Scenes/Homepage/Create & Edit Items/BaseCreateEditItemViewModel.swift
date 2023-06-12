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
    @Published private(set) var isSaving = false
    @Published private(set) var customFieldsSupported = false
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
    let featureFlagsRepository: FeatureFlagsRepositoryProtocol
    let preferences: Preferences
    let logger: Logger
    let vaults: [Vault]

    var hasEmptyCustomField: Bool { customFieldUiModels.contains(where: { $0.customField.content.isEmpty }) }
    var didEditSomething = false

    weak var delegate: CreateEditItemViewModelDelegate?
    var cancellables = Set<AnyCancellable>()

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol,
         upgradeChecker: UpgradeCheckerProtocol,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol,
         vaults: [Vault],
         preferences: Preferences,
         logManager: LogManager) throws {
        let vaultShareId: String
        switch mode {
        case .create(let shareId, _):
            vaultShareId = shareId
        case .edit(let itemContent):
            vaultShareId = itemContent.shareId
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }

        guard let vault = vaults.first(where: { $0.shareId == vaultShareId }) ?? vaults.first else {
            throw PPError.vault(.vaultNotFound(vaultShareId))
        }
        self.selectedVault = vault
        self.mode = mode
        self.itemRepository = itemRepository
        self.upgradeChecker = upgradeChecker
        self.featureFlagsRepository = featureFlagsRepository
        self.preferences = preferences
        self.logger = .init(manager: logManager)
        self.vaults = vaults
        self.bindValues()
        self.pickPrimaryVaultIfApplicable()
        self.checkIfCustomFieldsAreSupported()
        self.checkIfAbleToAddMoreCustomFields()
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
    /// Automatically switch to primary vault if free user. They won't be able to select other vaults anyway.
    func pickPrimaryVaultIfApplicable() {
        guard case .create = mode, vaults.count > 1, !selectedVault.isPrimary else { return }
        Task { @MainActor in
            do {
                let isFreeUser = try await upgradeChecker.isFreeUser()
                if isFreeUser, let primaryVault = vaults.first(where: { $0.isPrimary }) {
                    selectedVault = primaryVault
                }
            } catch {
                logger.error(error)
                delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

    func checkIfCustomFieldsAreSupported() {
        Task { @MainActor in
            do {
                let featureFlags = try await featureFlagsRepository.getFlags()
                customFieldsSupported = featureFlags.customFields
            } catch {
                logger.error(error)
                delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

    func checkIfAbleToAddMoreCustomFields() {
        Task { @MainActor in
            do {
                let isFreeUser = try await upgradeChecker.isFreeUser()
                canAddMoreCustomFields = !isFreeUser
            } catch {
                logger.error(error)
                delegate?.createEditItemViewModelDidEncounter(error: error)
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
                delegate?.createEditItemViewModelDidEncounter(error: error)
            }
        }
    }

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
        delegate?.createEditItemViewModelWantsToChangeVault(selectedVault: selectedVault, delegate: self)
    }
}

// MARK: - VaultSelectorViewModelDelegate
extension BaseCreateEditItemViewModel: VaultSelectorViewModelDelegate {
    func vaultSelectorViewModelWantsToUpgrade() {
        delegate?.createEditItemViewModelWantsToUpgrade()
    }

    func vaultSelectorViewModelDidSelect(vault: Vault) {
        self.selectedVault = vault
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
