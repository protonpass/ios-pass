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
import Screens
import SwiftUI
import UseCases

typealias ScanResponsePublisher = PassthroughSubject<(any ScanResult)?, any Error>

@MainActor
protocol CreateEditItemViewModelDelegate: AnyObject {
    func createEditItemViewModelWantsToAddCustomField(delegate: any CustomFieldAdditionDelegate,
                                                      shouldDisplayTotp: Bool)
    func createEditItemViewModelWantsToEditCustomFieldTitle(_ uiModel: CustomFieldUiModel,
                                                            delegate: any CustomFieldEditionDelegate)
}

enum ItemMode: Equatable, Hashable {
    case create(shareId: String?, type: ItemCreationType)
    case clone(ItemContent)
    case edit(ItemContent)

    var isEditMode: Bool {
        switch self {
        case .edit:
            true
        default:
            false
        }
    }

    var canChangeVault: Bool {
        switch self {
        case .clone, .create:
            true
        default:
            false
        }
    }
}

enum ItemCreationType: Equatable, Hashable {
    case note(title: String, note: String)
    case alias
    // swiftlint:disable:next enum_case_associated_values_count
    case login(title: String? = nil,
               url: String? = nil,
               note: String? = nil,
               totpUri: String? = nil,
               autofill: Bool,
               passkeyCredentialRequest: PasskeyCredentialRequest? = nil)
    case creditCard

    case identity

    var itemContentType: ItemContentType {
        switch self {
        case .note:
            .note
        case .alias:
            .alias
        case .login:
            .login
        case .creditCard:
            .creditCard
        case .identity:
            .identity
        }
    }
}

@MainActor
class BaseCreateEditItemViewModel: ObservableObject, CustomFieldAdditionDelegate, CustomFieldEditionDelegate {
    @Published var selectedVault: Share
    @Published private(set) var isFreeUser = false
    @Published private(set) var isSaving = false
    @Published private(set) var canAddMoreCustomFields = true
    @Published private(set) var canScanDocuments = false
    @Published private(set) var files = [FileAttachment]()
    @Published private(set) var isUploadingFile = false
    @Published private(set) var dismissedFileAttachmentsBanner = false
    @Published var recentlyAddedOrEditedField: CustomFieldUiModel?

    @Published var customFieldUiModels = [CustomFieldUiModel]()
    @Published var isShowingVaultSelector = false
    @Published var isObsolete = false
    @Published var isShowingDiscardAlert = false

    // Scanning
    @Published var isShowingScanner = false
    let scanResponsePublisher = ScanResponsePublisher()

    let mode: ItemMode
    let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    let upgradeChecker: any UpgradeCheckerProtocol
    let logger = resolve(\SharedToolingContainer.logger)
    let vaults: [Share]
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)
    private let getUserPreferences = resolve(\SharedUseCasesContainer.getUserPreferences)
    private let updateUserPreferences = resolve(\SharedUseCasesContainer.updateUserPreferences)
    @LazyInjected(\SharedServiceContainer.userManager) var userManager
    @LazyInjected(\SharedToolingContainer.preferencesManager) var preferencesManager
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus
    @LazyInjected(\SharedUseCasesContainer.generateDatedFileName) private var generateDatedFileName
    @LazyInjected(\SharedUseCasesContainer.writeToUrl) private var writeToUrl
    @LazyInjected(\SharedUseCasesContainer.getFileSize) private var getFileSize
    @LazyInjected(\SharedUseCasesContainer.getMimeType) private var getMimeType
    @LazyInjected(\SharedUseCasesContainer.getFileGroup) private var getFileGroup
    @LazyInjected(\SharedUseCasesContainer.formatFileAttachmentSize) private var formatFileAttachmentSize

    var fileAttachmentsEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFileAttachmentsV1)
    }

    var showFileAttachmentsBanner: Bool {
        fileAttachmentsEnabled && !dismissedFileAttachmentsBanner
    }

    var hasEmptyCustomField: Bool {
        customFieldUiModels.filter { $0.customField.type != .text }.contains(where: \.customField.content.isEmpty)
    }

    var isSaveable: Bool { true }

    var shouldUpgrade: Bool { false }

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    weak var delegate: (any CreateEditItemViewModelDelegate)?
    var cancellables = Set<AnyCancellable>()

    private var uploadFileTask: Task<Void, Never>?

    init(mode: ItemMode,
         upgradeChecker: any UpgradeCheckerProtocol,
         vaults: [Share]) throws {
        let vaultShareId: String?
        switch mode {
        case let .create(shareId, _):
            vaultShareId = shareId
        case let .clone(itemContent), let .edit(itemContent):
            vaultShareId = itemContent.shareId
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }

        let lastCreatedItemVault: Share? = if let shareId = getUserPreferences().lastCreatedItemShareId {
            vaults.first { $0.shareId == shareId && $0.canEdit }
        } else {
            nil
        }

        let editableVault = vaults.first { $0.shareId == vaultShareId && $0.canEdit }
        let oldestOwnedVault = vaults.autofillAllowedVaults.oldestOwned

        guard let vault = editableVault ?? lastCreatedItemVault ?? oldestOwnedVault else {
            throw PassError.vault(.noEditableVault)
        }

        selectedVault = vault
        self.mode = mode
        self.upgradeChecker = upgradeChecker
        self.vaults = vaults
        bindValues()
        setUp()
    }

    func bindValues() {}

    var itemContentType: ItemContentType {
        fatalError("Must be overridden by subclasses")
    }

    // swiftlint:disable:next unavailable_function
    func generateItemContent() async -> ItemContentProtobuf? {
        fatalError("Must be overridden by subclasses")
    }

    /// The new passkey associated with this item
    func newPasskey() async throws -> CreatePasskeyResponse? { nil }

    func saveButtonTitle() -> String {
        switch mode {
        case .clone, .create:
            #localized("Create")
        case .edit:
            #localized("Save")
        }
    }

    func additionalEdit() async throws -> Bool { false }

    func generateAliasCreationInfo() -> AliasCreationInfo? { nil }
    func generateAliasItemContent() -> ItemContentProtobuf? { nil }

    func telemetryEventTypes() -> [TelemetryEventType] { [] }

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

    func customFieldAdded(_ customField: CustomField) {
        let uiModel = CustomFieldUiModel(customField: customField)
        customFieldUiModels.append(uiModel)
        recentlyAddedOrEditedField = uiModel
    }
}

// MARK: - Private APIs

private extension BaseCreateEditItemViewModel {
    func setUp() {
        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
                canAddMoreCustomFields = !isFreeUser
                canScanDocuments = DocScanner.isSupported
            } catch {
                handle(error)
            }
        }

        dismissedFileAttachmentsBanner =
            preferencesManager.appPreferences.unwrapped().dismissedFileAttachmentsBanner

        preferencesManager
            .appPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.dismissedFileAttachmentsBanner)
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self else { return }
                dismissedFileAttachmentsBanner = newValue
            }
            .store(in: &cancellables)
    }

    func createItem(for type: ItemContentType) async throws -> SymmetricallyEncryptedItem? {
        let shareId = selectedVault.shareId
        guard let itemContent = await generateItemContent() else {
            logger.warning("No item content")
            return nil
        }
        let userId = try await userManager.getActiveUserId()
        switch type {
        case .alias:
            if let aliasCreationInfo = generateAliasCreationInfo() {
                return try await itemRepository.createAlias(userId: userId,
                                                            info: aliasCreationInfo,
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
                    .createAliasAndOtherItem(userId: userId,
                                             info: aliasCreationInfo,
                                             aliasItemContent: aliasItemContent,
                                             otherItemContent: itemContent,
                                             shareId: shareId)
                return createdLoginItem
            }

        default:
            break
        }

        return try await itemRepository.createItem(userId: userId, itemContent: itemContent, shareId: shareId)
    }

    /// Return `true` if item is edited, `false` otherwise
    func editItem(oldItemContent: ItemContent) async throws -> Bool {
        let additionallyEdited = try await additionalEdit()
        let itemId = oldItemContent.itemId
        let shareId = oldItemContent.shareId
        guard let oldItem = try await itemRepository.getItem(shareId: shareId,
                                                             itemId: itemId) else {
            throw PassError.itemNotFound(oldItemContent)
        }
        guard let newItemContent = await generateItemContent() else {
            logger.warning("No new item content")
            return additionallyEdited
        }
        guard !oldItemContent.protobuf.isLooselyEqual(to: newItemContent) else {
            logger.trace("Skipped editing because no changes \(oldItemContent.debugDescription)")
            return additionallyEdited
        }
        try await itemRepository.updateItem(userId: oldItem.userId,
                                            oldItem: oldItem.item,
                                            newItemContent: newItemContent,
                                            shareId: oldItem.shareId)
        return true
    }

    func handle(_ error: any Error) {
        logger.error(error)
        if let passError = error as? PassError,
           case let .fileAttachment(reason) = passError,
           case .fileTooLarge = reason {
            let message =
                #localized("The selected file exceeds the size limit. Please choose a file smaller than 100 MB.")
            router.display(element: .errorMessage(message))
        } else {
            router.display(element: .displayErrorBanner(error))
        }
    }
}

// MARK: - Public APIs

extension BaseCreateEditItemViewModel {
    func dismissFileAttachmentsBanner() {
        Task {
            do {
                try await preferencesManager.updateAppPreferences(\.dismissedFileAttachmentsBanner,
                                                                  value: true)
            } catch {
                handle(error)
            }
        }
    }

    func addCustomField() {
        delegate?.createEditItemViewModelWantsToAddCustomField(delegate: self, shouldDisplayTotp: true)
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

    @objc
    func save() {
        Task { [weak self] in
            guard let self else { return }

            defer { isSaving = false }
            isSaving = true

            do {
                let handleCreation: (ItemContentType) async throws -> Void = { [weak self] type in
                    guard let self else { return }
                    logger.trace("Creating item")
                    if let createdItem = try await createItem(for: type) {
                        logger.info("Created \(createdItem.debugDescription)")
                        let passkey = try await newPasskey()
                        router.present(for: .createItem(item: createdItem,
                                                        type: type,
                                                        createPasskeyResponse: passkey))
                    }
                    try await updateUserPreferences(\.lastCreatedItemShareId, value: selectedVault.shareId)
                }

                switch mode {
                case let .create(_, type):
                    try await handleCreation(type.itemContentType)

                case let .clone(itemContent):
                    try await handleCreation(itemContent.type)

                case let .edit(oldItemContent):
                    logger.trace("Editing \(oldItemContent.debugDescription)")
                    let updated = try await editItem(oldItemContent: oldItemContent)
                    logger.info("Edited \(oldItemContent.debugDescription)")
                    router.present(for: .updateItem(type: itemContentType, updated: updated))
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
        Task { [weak self] in
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
}

// MARK: - FileAttachmentsEditHandler

extension BaseCreateEditItemViewModel: FileAttachmentsEditHandler {
    var fileAttachmentsSectionPrimaryColor: UIColor {
        itemContentType.normMajor2Color
    }

    var fileAttachmentsSectionSecondaryColor: UIColor {
        itemContentType.normMinor1Color
    }

    func generateDatedFileName(prefix: String, extension: String) -> String {
        generateDatedFileName(prefix: prefix, extension: `extension`, date: .now)
    }

    func writeToTemporaryDirectory(data: Data, fileName: String) throws -> URL {
        let fileSize = UInt64(data.count)
        guard fileSize < Constants.Utils.maxFileSizeInBytes else {
            throw PassError.fileAttachment(.fileTooLarge(fileSize))
        }
        return try writeToUrl(data: data,
                              fileName: fileName,
                              baseUrl: FileManager.default.temporaryDirectory)
    }

    func handleAttachment(_ url: URL) {
        uploadFileTask?.cancel()
        uploadFileTask = Task { [weak self] in
            guard let self else { return }
            defer {
                isUploadingFile = false
            }
            let fileId = UUID().uuidString
            do {
                isUploadingFile = true
                let fileSize = try getFileSize(for: url)
                if fileSize > Constants.Utils.maxFileSizeInBytes {
                    // Optionally remove the file, we don't care if errors occur here
                    // because it should be in temporary directory which is cleaned up
                    // by the system anyway
                    try? FileManager.default.removeItem(at: url)
                    throw PassError.fileAttachment(.fileTooLarge(fileSize))
                }
                let mimeType = try getMimeType(of: url)
                let fileGroup = getFileGroup(mimeType: mimeType)
                let formattedFileSize = formatFileAttachmentSize(fileSize)
                let file = PendingFileAttachment(id: fileId,
                                                 metadata: .init(url: url,
                                                                 mimeType: mimeType,
                                                                 fileGroup: fileGroup,
                                                                 size: fileSize,
                                                                 formattedSize: formattedFileSize))
                files.append(.pending(file))
                try await Task.sleep(seconds: 0.5)
                if Bool.random() {
                    files.updateState(id: fileId, newState: .uploaded(remoteId: ""))
                } else {
                    throw PassError.fileAttachment(.noPngData)
                }
            } catch {
                files.updateState(id: fileId, newState: .error(error))
                handle(error)
            }
        }
    }

    func handleAttachmentError(_ error: any Error) {
        handle(error)
    }

    func retryUpload(attachment: FileAttachment) {
        files.updateState(id: attachment.id, newState: .uploaded(remoteId: ""))
    }

    func rename(attachment: FileAttachment, newName: String) {
        print(attachment)
        print(newName)
    }

    func delete(attachment: FileAttachment) {
        print(attachment)
    }

    func deleteAllAttachments() {
        print(#function)
    }
}
