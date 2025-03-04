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

// swiftlint:disable file_length
import Client
import Combine
import Core
import DesignSystem
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

    var itemContent: ItemContent? {
        switch self {
        case let .clone(content), let .edit(content):
            content
        default:
            nil
        }
    }

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
    case sshKey
    case wifi
    case custom(CustomItemTemplate)

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
        case .sshKey:
            .sshKey
        case .wifi:
            .wifi
        case .custom:
            .custom
        }
    }
}

private struct PendingFileNameUpdate: Sendable {
    let fileId: String
    let newName: String
}

@MainActor
class BaseCreateEditItemViewModel: ObservableObject, CustomFieldAdditionDelegate, CustomFieldEditionDelegate {
    @Published var selectedVault: Share
    @Published private(set) var isFreeUser = false
    @Published private(set) var isSaving = false
    @Published private(set) var canAddMoreCustomFields = true
    @Published private(set) var canScanDocuments = false
    /// Hold the user edit list of updated files. Need to compare with the attached files in order to add and
    /// remove accordingly
    @Published private(set) var files = [FileAttachment]()
    /// Hold the remote files currently attached to the item
    @Published private(set) var attachedFiles: FetchableObject<[ItemFile]>?
    @Published private(set) var isUploadingFile = false
    @Published private(set) var dismissedFileAttachmentsBanner = false
    @Published var filePreviewMode: FileAttachmentPreviewMode?
    @Published var fileToDelete: FileAttachmentUiModel?
    @Published var recentlyAddedOrEditedField: CustomFieldUiModel?

    @Published var customFieldUiModels = [CustomFieldUiModel]()

    @Published var customSectionUiModels = [CustomSectionUiModel]()
    @Published var showAddCustomSectionAlert = false
    @Published var customSectionToRename: CustomSectionUiModel?

    @Published var isShowingVaultSelector = false
    @Published var isObsolete = false
    @Published var isShowingDiscardAlert = false

    // Scanning
    @Published var isShowingScanner = false
    let scanResponsePublisher = ScanResponsePublisher()

    private var pendingFileNameUpdates = [PendingFileNameUpdate]()

    private lazy var renameAttachmentDelegate = RenameAttachmentDelegate()

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
    @LazyInjected(\SharedRepositoryContainer.fileAttachmentRepository) private var fileRepository
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus
    @LazyInjected(\SharedUseCasesContainer.generateDatedFileName) private var generateDatedFileName
    @LazyInjected(\SharedUseCasesContainer.writeToUrl) private var writeToUrl
    @LazyInjected(\SharedUseCasesContainer.getFileSize) private var getFileSize
    @LazyInjected(\SharedUseCasesContainer.getMimeType) private var getMimeType
    @LazyInjected(\SharedUseCasesContainer.getFileGroup) private var getFileGroup
    @LazyInjected(\SharedUseCasesContainer.formatFileAttachmentSize) private var formatFileAttachmentSize
    @LazyInjected(\SharedUseCasesContainer.getFilesToLink) private var getFilesToLink
    @LazyInjected(\SharedUseCasesContainer.downloadAndDecryptFile) private var downloadAndDecryptFile

    var fileAttachmentsEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFileAttachmentsV1)
    }

    var showFileAttachmentsBanner: Bool {
        fileAttachmentsEnabled && !dismissedFileAttachmentsBanner
    }

    var isFetchingAttachedFiles: Bool {
        attachedFiles?.isFetching == true
    }

    var fetchAttachedFilesError: (any Error)? {
        attachedFiles?.error
    }

    var fileUiModels: [FileAttachmentUiModel] {
        var uiModels = [FileAttachmentUiModel]()
        for file in files {
            switch file {
            case let .pending(pending):
                uiModels.append(.init(id: pending.id,
                                      persistentFileUID: nil,
                                      url: pending.metadata.url,
                                      state: pending.uploadState,
                                      name: pending.metadata.name,
                                      group: pending.metadata.fileGroup,
                                      formattedSize: pending.metadata.formattedSize))
            case let .item(itemFile):
                let formattedSize = formatFileAttachmentSize(itemFile.size)
                if let name = itemFile.name,
                   let mimeType = itemFile.mimeType {
                    let fileGroup = getFileGroup(mimeType: mimeType)
                    uiModels.append(.init(id: itemFile.fileID,
                                          persistentFileUID: itemFile.persistentFileUID,
                                          url: nil,
                                          state: .uploaded,
                                          name: name,
                                          group: fileGroup,
                                          formattedSize: formattedSize))
                } else {
                    assertionFailure("Missing file name and MIME type")
                }
            }
        }
        return uiModels
    }

    var hasEmptyCustomField: Bool {
        customFieldUiModels.filter { $0.customField.type != .text }.contains(where: \.customField.content.isEmpty)
    }

    var isSaveable: Bool {
        !isUploadingFile && fileUiModels.allSatisfy { $0.state == .uploaded }
    }

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

    func fetchAttachedFiles() async {
        guard fileAttachmentsEnabled,
              mode.isEditMode, // Do not fetch attachments when cloning items
              let itemContent = mode.itemContent,
              itemContent.item.hasFiles else {
            attachedFiles = nil
            return
        }
        do {
            attachedFiles = .fetching
            let userId = try await userManager.getActiveUserId()
            let files = try await fileRepository.getActiveItemFiles(userId: userId,
                                                                    item: itemContent,
                                                                    share: selectedVault)
            attachedFiles = .fetched(files)
            for file in files {
                self.files.upsert(file)
            }
        } catch {
            attachedFiles = .error(error)
        }
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
        var edited = try await additionalEdit()
        let itemId = oldItemContent.itemId
        let shareId = oldItemContent.shareId
        guard let oldItem = try await itemRepository.getItem(shareId: shareId,
                                                             itemId: itemId) else {
            throw PassError.itemNotFound(oldItemContent)
        }

        let renamedFiles = try await processPendingFileNameUpdates()
        edited = edited || renamedFiles

        guard let newItemContent = await generateItemContent() else {
            logger.warning("No new item content")
            return edited
        }

        var updatedItem: any ItemIdentifiable = oldItem
        if !oldItemContent.protobuf.isLooselyEqual(to: newItemContent) {
            updatedItem = try await itemRepository.updateItem(userId: oldItem.userId,
                                                              oldItem: oldItem.item,
                                                              newItemContent: newItemContent,
                                                              shareId: oldItem.shareId)
            edited = true
        }

        let linkedFiles = try await linkFiles(to: updatedItem)
        edited = edited || linkedFiles

        return edited
    }

    func linkFiles(to item: any ItemIdentifiable) async throws -> Bool {
        let attachedFiles = attachedFiles?.fetchedObject ?? []

        let filesToLink = getFilesToLink(attachedFiles: attachedFiles, updatedFiles: files)
        guard !filesToLink.isEmpty else {
            logger.debug("No files to link to \(item.debugDescription)")
            return false
        }

        let userId = try await userManager.getActiveUserId()
        if !filesToLink.toAdd.isEmpty {
            logger.debug("Linking \(filesToLink.toAdd.count) files to \(item.debugDescription)")
        }
        if !filesToLink.toRemove.isEmpty {
            logger.debug("Removing \(filesToLink.toAdd.count) files to \(item.debugDescription)")
        }
        try await fileRepository.linkFilesToItem(userId: userId,
                                                 pendingFilesToAdd: filesToLink.toAdd,
                                                 existingFileIdsToRemove: filesToLink.toRemove,
                                                 item: item)
        logger.info("Done linking files to \(item.debugDescription)")
        return true
    }
}

// MARK: - Public APIs

extension BaseCreateEditItemViewModel {
    func handle(_ error: any Error) {
        logger.error(error)

        var customErrorMessage: String?
        if let passError = error as? PassError,
           case let .fileAttachment(reason) = passError {
            customErrorMessage = switch reason {
            case .fileTooLarge:
                #localized("The selected file exceeds the size limit. Please choose a file smaller than 100 MB.")
            case .emptyFile:
                #localized("The selected file is empty. Please check the file and try again.")
            default:
                nil
            }
        }

        if let customErrorMessage {
            router.display(element: .errorMessage(customErrorMessage))
        } else {
            router.display(element: .displayErrorBanner(error))
        }
    }

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
                        _ = try await processPendingFileNameUpdates()
                        _ = try await linkFiles(to: createdItem)
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

    func addCustomSection(_ title: String) {
        customSectionUiModels.append(.init(title: title,
                                           isCollapsed: false,
                                           fields: []))
    }
}

// MARK: - Custom section

extension BaseCreateEditItemViewModel {}

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
        guard !data.isEmpty else {
            throw PassError.fileAttachment(.emptyFile)
        }
        let fileSize = UInt64(data.count)
        guard fileSize < Constants.Attachment.maxFileSizeInBytes else {
            throw PassError.fileAttachment(.fileTooLarge(fileSize))
        }
        return try writeToUrl(data: data,
                              fileName: fileName,
                              baseUrl: FileManager.default.temporaryDirectory)
    }

    func open(attachment: FileAttachmentUiModel) {
        switch mode {
        case .clone, .create:
            // When creating or cloning, all files are pending
            if let file = files.first(where: { $0.id == attachment.id }),
               case let .pending(pendingFile) = file {
                filePreviewMode = .pending(pendingFile.metadata.url)
            }

        case .edit:
            guard let file = files.first(where: { $0.id == attachment.id }) else { return }
            switch file {
            case let .pending(pendingFile):
                filePreviewMode = .pending(pendingFile.metadata.url)

            case let .item(itemFile):
                filePreviewMode = .item(itemFile, self, .none)
            }
        }
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
                if fileSize == 0 {
                    throw PassError.fileAttachment(.emptyFile)
                }

                if fileSize > Constants.Attachment.maxFileSizeInBytes {
                    // Optionally remove the file, we don't care if errors occur here
                    // because it should be in temporary directory which is cleaned up
                    // by the system anyway
                    #if !targetEnvironment(simulator)
                    try? FileManager.default.removeItem(at: url)
                    #endif
                    throw PassError.fileAttachment(.fileTooLarge(fileSize))
                }
                let mimeType = try getMimeType(of: url)
                let fileGroup = getFileGroup(mimeType: mimeType)
                let formattedFileSize = formatFileAttachmentSize(fileSize)
                let file = try PendingFileAttachment(id: fileId,
                                                     key: .random(),
                                                     metadata: .init(url: url,
                                                                     mimeType: mimeType,
                                                                     fileGroup: fileGroup,
                                                                     size: fileSize,
                                                                     formattedSize: formattedFileSize))
                try await createEncryptAndUpload(file)
            } catch {
                if let file = files.first(where: { $0.id == fileId }),
                   case var .pending(pendingFile) = file {
                    pendingFile.uploadState = .error(error)
                    files.upsert(pendingFile)
                }
                handle(error)
            }
        }
    }

    func handleAttachmentError(_ error: any Error) {
        handle(error)
    }

    func retryFetchAttachedFiles() {
        Task { [weak self] in
            guard let self else { return }
            await fetchAttachedFiles()
        }
    }

    func retryUpload(attachment: FileAttachmentUiModel) {
        guard let file = files.first(where: { $0.id == attachment.id }),
              case var .pending(file) = file else { return }
        uploadFileTask?.cancel()
        uploadFileTask = Task { [weak self] in
            guard let self else { return }
            defer {
                isUploadingFile = false
            }
            do {
                isUploadingFile = true
                try await createEncryptAndUpload(file)
            } catch {
                file.uploadState = .error(error)
                files.upsert(file)
                handle(error)
            }
        }
    }

    func rename(attachment: FileAttachmentUiModel, newName: String) {
        let update = PendingFileNameUpdate(fileId: attachment.id, newName: newName)
        pendingFileNameUpdates.upsert(update, isEqual: { $0.fileId == $1.fileId })

        switch files.first(where: { $0.id == attachment.id }) {
        case var .pending(pendingFile):
            pendingFile.metadata.name = newName
            files.upsert(pendingFile)

        case var .item(itemFile):
            itemFile.name = newName
            files.upsert(itemFile)

        default:
            assertionFailure("No item with id \(attachment.id)")
        }
    }

    func showRenameAlert(attachment: FileAttachmentUiModel) {
        let alert = UIAlertController(title: #localized("Rename file"),
                                      message: nil,
                                      preferredStyle: .alert)

        let renameHandler: (UIAlertAction) -> Void = { [weak self] _ in
            guard let self,
                  let updatedFileName = alert.textFields?.first?.text else { return }
            rename(attachment: attachment, newName: updatedFileName)
        }

        let renameAction = UIAlertAction(title: #localized("Rename"),
                                         style: .default,
                                         handler: renameHandler)

        alert.addTextField { [weak self] textField in
            guard let self else { return }
            textField.text = attachment.name
            textField.autocapitalizationType = .sentences
            textField.delegate = renameAttachmentDelegate
            textField.setOnTextChangeListener {
                renameAction.isEnabled = textField.text?.isEmpty == false
            }
        }

        alert.addAction(renameAction)
        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))

        router.present(for: .alert(alert))
    }

    func showDeleteAlert(attachment: FileAttachmentUiModel) {
        fileToDelete = attachment
    }

    /// Return `true` if there was something to process, `false` otherwise
    func processPendingFileNameUpdates() async throws -> Bool {
        let userId = try await userManager.getActiveUserId()
        var processed = false
        for update in pendingFileNameUpdates {
            processed = true
            switch files.first(where: { $0.id == update.fileId }) {
            case let .pending(pendingFile):
                _ = try await fileRepository.updatePendingFileName(userId: userId,
                                                                   file: pendingFile,
                                                                   newName: update.newName)

            case let .item(itemFile):
                if let itemContent = mode.itemContent {
                    _ = try await fileRepository.updateItemFileName(userId: userId,
                                                                    item: itemContent,
                                                                    file: itemFile,
                                                                    newName: update.newName)
                }

            default:
                assertionFailure("No item with id \(update.fileId)")
            }
        }
        pendingFileNameUpdates.removeAll()
        return processed
    }

    func delete(attachment: FileAttachmentUiModel) {
        files.removeAll(where: { $0.id == attachment.id })
    }

    func deleteAllAttachments() {
        files.removeAll()
    }

    func upsellFileAttachments() {
        let config = UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                                title: #localized("File attachments"),
                                                description: UpsellEntry.fileAttachments.description,
                                                upsellElements: UpsellEntry.fileAttachments.upsellElements,
                                                ctaTitle: #localized("Get Pass Plus"))
        router.present(for: .upselling(config))
    }
}

extension BaseCreateEditItemViewModel: FileAttachmentPreviewHandler {
    func downloadAndDecrypt(file: ItemFile) async throws
        -> AsyncThrowingStream<ProgressEvent<URL>, any Error> {
        guard case let .edit(itemContent) = mode else {
            throw PassError.fileAttachment(.failedToDownloadNoFetchedFiles)
        }
        let userId = try await userManager.getActiveUserId()
        return try await downloadAndDecryptFile(userId: userId,
                                                item: itemContent,
                                                file: file)
    }
}

private extension BaseCreateEditItemViewModel {
    func createEncryptAndUpload(_ file: PendingFileAttachment) async throws {
        var file = file

        file.uploadState = .uploading(0.0)
        files.upsert(file)

        let userId = try await userManager.getActiveUserId()
        let remoteFile = try await fileRepository.createPendingFile(userId: userId,
                                                                    file: file)
        file.remoteId = remoteFile.fileID
        files.upsert(file)

        let progressStream = try await fileRepository.uploadFile(userId: userId, file: file)

        for try await progress in progressStream {
            if progress >= 1 {
                file.uploadState = .uploaded
            } else {
                file.uploadState = .uploading(progress)
            }
            files.upsert(file)
        }

        file.uploadState = .uploaded
        files.upsert(file)
        addTelemetryEvent(with: .fileUploaded(mimeType: file.metadata.mimeType))
    }
}

private final class RenameAttachmentDelegate: NSObject, UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Automatically focus on file name and ignore file extension
        // base on the last position of "." character
        guard let fullFileName = textField.text,
              let lastDotIndex = fullFileName.lastIndex(of: ".") else { return }

        let fileNameLength = fullFileName.distance(from: fullFileName.startIndex,
                                                   to: lastDotIndex)

        guard let fileNameEndPosition = textField.position(from: textField.beginningOfDocument,
                                                           offset: fileNameLength) else {
            return
        }
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument,
                                                          to: fileNameEndPosition)
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // Disallow leading and trailing spaces for file names
        guard let currentText = textField.text,
              let stringRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return !updatedText.hasPrefix(" ") && !updatedText.hasSuffix(" ")
    }
}

// swiftlint:enable file_length
