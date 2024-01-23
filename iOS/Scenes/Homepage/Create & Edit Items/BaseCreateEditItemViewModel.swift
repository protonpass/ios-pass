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
import DocScanner
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreLogin

@MainActor
protocol CreateEditItemViewModelDelegate: AnyObject {
    func createEditItemViewModelWantsToAddCustomField(delegate: CustomFieldAdditionDelegate)
    func createEditItemViewModelWantsToEditCustomFieldTitle(_ uiModel: CustomFieldUiModel,
                                                            delegate: CustomFieldEditionDelegate)
    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType)
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType, updated: Bool)
}

enum ItemMode {
    case create(shareId: String, type: ItemCreationType)
    case edit(ItemContent)

    var isEditMode: Bool {
        switch self {
        case .edit:
            true
        default:
            false
        }
    }
}

enum ItemCreationType {
    case note(title: String, note: String)
    case alias
    case login(title: String?, url: String?, note: String?, autofill: Bool)
    case other
}

@MainActor
class BaseCreateEditItemViewModel {
    @Published private(set) var selectedVault: Vault
    @Published private(set) var isFreeUser = false
    @Published private(set) var isSaving = false
    @Published private(set) var canAddMoreCustomFields = true
    @Published private(set) var recentlyAddedOrEditedField: CustomFieldUiModel?

    @Published var customFieldUiModels = [CustomFieldUiModel]()
    @Published var isObsolete = false

    // Scanning
    @Published var isShowingScanner = false
    let scanResponsePublisher: PassthroughSubject<ScanResult?, Error> = .init()

    let mode: ItemMode
    let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    let upgradeChecker: UpgradeCheckerProtocol
    let logger = resolve(\SharedToolingContainer.logger)
    let vaults: [Vault]
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let getMainVault = resolve(\SharedUseCasesContainer.getMainVault)
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)

    var hasEmptyCustomField: Bool {
        customFieldUiModels.filter { $0.customField.type != .text }.contains(where: \.customField.content.isEmpty)
    }

    var didEditSomething: Bool {
        switch mode {
        case .create:
            return true
        case let .edit(oldItemContent):
            if let newItemContent = generateItemContent() {
                return !oldItemContent.protobuf.isLooselyEqual(to: newItemContent)
            }
            return true
        }
    }

    weak var delegate: CreateEditItemViewModelDelegate?
    var cancellables = Set<AnyCancellable>()

    init(mode: ItemMode,
         upgradeChecker: UpgradeCheckerProtocol,
         vaults: [Vault]) throws {
        let vaultShareId: String
        switch mode {
        case let .create(shareId, _):
            vaultShareId = shareId
        case let .edit(itemContent):
            vaultShareId = itemContent.shareId
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }

        guard let vault = vaults.first(where: { $0.shareId == vaultShareId }) ?? vaults.first else {
            throw PassError.vault(.vaultNotFound(vaultShareId))
        }

        if vault.canEdit {
            selectedVault = vault
        } else {
            guard let vault = vaults.twoOldestVaults.owned ?? vaults.first else {
                throw PassError.vault(.vaultNotFound(vaultShareId))
            }
            selectedVault = vault
        }
        self.mode = mode
        self.upgradeChecker = upgradeChecker
        self.vaults = vaults
        bindValues()
        setUp()
    }

    func bindValues() {}

    // swiftlint:disable:next unavailable_function
    func itemContentType() -> ItemContentType {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func generateItemContent() -> ItemContentProtobuf? {
        fatalError("Must be overridden by subclasses")
    }

    func saveButtonTitle() -> String {
        switch mode {
        case .create:
            #localized("Create")
        case .edit:
            #localized("Save")
        }
    }

    func additionalEdit() async throws {}

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }
    func generateAliasItemContent() -> ItemContentProtobuf? { nil }

    func telemetryEventTypes() -> [TelemetryEventType] { [] }
}

// MARK: - Private APIs

private extension BaseCreateEditItemViewModel {
    func setUp() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
                canAddMoreCustomFields = !isFreeUser
                if isFreeUser,
                   case .create = mode, vaults.count > 1,
                   let mainVault = await getMainVault() {
                    selectedVault = mainVault
                }
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }

        vaultsManager.$vaultSelection
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection in
                guard let self,
                      let newSelectedVault = selection.preciseVault,
                      newSelectedVault != selectedVault else {
                    return
                }
                selectedVault = newSelectedVault
            }
            .store(in: &cancellables)
    }

    func createItem(for type: ItemCreationType) async throws -> SymmetricallyEncryptedItem? {
        let shareId = selectedVault.shareId
        guard let itemContent = generateItemContent() else {
            logger.warning("No item content")
            return nil
        }

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

    /// Return `true` if item is edited, `false` otherwise
    func editItem(oldItemContent: ItemContent) async throws -> Bool {
        try await additionalEdit()
        let itemId = oldItemContent.itemId
        let shareId = oldItemContent.shareId
        guard let oldItem = try await itemRepository.getItem(shareId: shareId,
                                                             itemId: itemId) else {
            throw PassError.itemNotFound(oldItemContent)
        }
        guard let newItemContent = generateItemContent() else {
            logger.warning("No new item content")
            return false
        }
        guard !oldItemContent.protobuf.isLooselyEqual(to: newItemContent) else {
            logger.trace("Skipped editing because no changes \(oldItemContent.debugDescription)")
            return false
        }
        try await itemRepository.updateItem(oldItem: oldItem.item,
                                            newItemContent: newItemContent,
                                            shareId: oldItem.shareId)
        return true
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
        router.present(for: .upgradeFlow)
    }

    func openScanner() {
        isShowingScanner = true
    }

    func save() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            defer { isSaving = false }
            isSaving = true

            do {
                switch mode {
                case let .create(_, type):
                    logger.trace("Creating item")
                    if let createdItem = try await createItem(for: type) {
                        logger.info("Created \(createdItem.debugDescription)")
                        delegate?.createEditItemViewModelDidCreateItem(createdItem, type: itemContentType())
                    }

                case let .edit(oldItemContent):
                    logger.trace("Editing \(oldItemContent.debugDescription)")
                    let updated = try await editItem(oldItemContent: oldItemContent)
                    logger.info("Edited \(oldItemContent.debugDescription)")
                    delegate?.createEditItemViewModelDidUpdateItem(itemContentType(),
                                                                   updated: updated)
                }

                addTelemetryEvent(with: telemetryEventTypes())
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    /// Refresh the item to detect changes.
    /// When changes happen, announce via `isObsolete` boolean  so the view can act accordingly
    func refresh() {
        guard case let .edit(itemContent) = mode else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard let updatedItem =
                    try await itemRepository.getItem(shareId: itemContent.shareId,
                                                     itemId: itemContent.item.itemID) else {
                    return
                }
                isObsolete = itemContent.item.revision != updatedItem.item.revision
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func changeVault() {
        router.present(for: .vaultSelection)
    }
}

// MARK: - CustomFieldTitleAlertHandlerDelegate

extension BaseCreateEditItemViewModel: CustomFieldAdditionDelegate {
    func customFieldAdded(_ customField: CustomField) {
        let uiModel = CustomFieldUiModel(customField: customField)
        customFieldUiModels.append(uiModel)
        recentlyAddedOrEditedField = uiModel
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
        recentlyAddedOrEditedField = uiModel
        customFieldUiModels[index] = uiModel.update(title: newTitle)
    }

    func customFieldEdited(_ uiModel: CustomFieldUiModel, content: String) {
        guard let index = customFieldUiModels.firstIndex(where: { $0.id == uiModel.id }) else {
            let message = "Custom field with id \(uiModel.id) not found"
            logger.error(message)
            assertionFailure(message)
            return
        }
        recentlyAddedOrEditedField = uiModel
        customFieldUiModels[index] = uiModel.update(content: content)
    }
}
