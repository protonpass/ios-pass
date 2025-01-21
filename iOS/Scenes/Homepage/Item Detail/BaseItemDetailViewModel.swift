//
// BaseItemDetailViewModel.swift
// Proton Pass - Created on 08/09/2022.
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
@preconcurrency import CryptoKit
import Entities
import Factory
import Macro
import Screens
import UIKit

@MainActor
protocol ItemDetailViewModelDelegate: AnyObject {
    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool)
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent)
    func itemDetailViewModelWantsToShowFullScreen(_ data: FullScreenData)
}

@MainActor
class BaseItemDetailViewModel: ObservableObject {
    @Published private(set) var isFreeUser = false
    @Published private(set) var isMonitored = false // Only applicable to login items
    @Published private(set) var files: FetchableObject<[ItemFile]> = .fetching
    @Published var filePreviewMode: FileAttachmentPreviewMode?
    @Published var urlToSave: URL?
    @Published var urlToShare: URL?
    @Published var moreInfoSectionExpanded = false
    @Published var showingTrashAliasAlert = false
    @Published var showingLeaveShareAlert = false
    @Published var showingVaultMoveAlert = false

    @Published private(set) var canDisplayFeatureDiscovery = false

    private var superBindValuesCalled = false

    var fileUiModels: [FileAttachmentUiModel] {
        guard case let .fetched(files) = files else {
            return []
        }
        var uiModels = [FileAttachmentUiModel]()
        for file in files {
            let formattedSize = formatFileAttachmentSize(file.size)
            if let name = file.name,
               let mimeType = file.mimeType {
                let fileGroup = getFileGroup(mimeType: mimeType)
                uiModels.append(.init(id: file.fileID,
                                      url: nil,
                                      state: .uploaded,
                                      name: name,
                                      group: fileGroup,
                                      formattedSize: formattedSize))
            } else {
                assertionFailure("Missing file name and MIME type")
            }
        }
        return uiModels
    }

    let isShownAsSheet: Bool
    let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)

    let upgradeChecker: any UpgradeCheckerProtocol
    private(set) var itemContent: ItemContent {
        didSet {
            customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        }
    }

    /// A `@Published` copy of `itemContent` because
    /// we need to pass it as `Binding` to `PermenentlyDeleteItemModifier`
    @Published var itemToBeDeleted: (any ItemTypeIdentifiable)?

    private(set) var customFieldUiModels: [CustomFieldUiModel]
    let vault: VaultListUiModel?
    let logger = resolve(\SharedToolingContainer.logger)

    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let canUserPerformActionOnVault = resolve(\UseCasesContainer.canUserPerformActionOnVault)
    private let pinItems = resolve(\SharedUseCasesContainer.pinItems)
    private let unpinItems = resolve(\SharedUseCasesContainer.unpinItems)
    private let toggleItemMonitoring = resolve(\UseCasesContainer.toggleItemMonitoring)
    private let addItemReadEvent = resolve(\UseCasesContainer.addItemReadEvent)
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private(set) var itemRepository
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private(set) var router
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) var getFeatureFlagStatus
    @LazyInjected(\SharedServiceContainer.itemContextMenuHandler) var itemContextMenuHandler
    @LazyInjected(\SharedServiceContainer.syncEventLoop) var syncEventLoop
    @LazyInjected(\UseCasesContainer.leaveShare) var leaveShareUsecase
    @LazyInjected(\SharedServiceContainer.userManager) var userManager
    @LazyInjected(\SharedRepositoryContainer.fileAttachmentRepository) private var fileRepository
    @LazyInjected(\SharedUseCasesContainer.formatFileAttachmentSize) private var formatFileAttachmentSize
    @LazyInjected(\SharedUseCasesContainer.getFileGroup) private var getFileGroup
    @LazyInjected(\SharedUseCasesContainer.generateFileTempUrl) private var generateFileTempUrl
    @LazyInjected(\SharedUseCasesContainer.downloadAndDecryptFile) private var downloadAndDecryptFile
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private(set) var accessRepository
    @LazyInjected(\SharedToolingContainer.preferencesManager) var preferencesManager

    var isAllowedToEdit: Bool {
        guard let vault else {
            return false
        }
        return canUserPerformActionOnVault(for: vault.vault)
    }

    var fileAttachmentsEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFileAttachmentsV1)
    }

    var showFileAttachmentsSection: Bool {
        fileAttachmentsEnabled &&
            itemContent.item.hasFiles &&
            (!files.isFetched || files.fetchedObject?.isEmpty == false)
    }

    var aliasSyncEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passSimpleLoginAliasesSync)
    }

    var itemSharingEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passItemSharingV1)
    }

    var canShareItem: Bool {
        vault?.vault.shareRole != .read && !itemContent.isAlias
    }

    // swiftlint:disable:next todo
    // TODO: have to check the calculation with new endpoints
    var numberOfSharedMembers: Int {
        var members = itemContent.item.shareCount

        if let vault = vault?.vault, vault.isVaultRepresentation, vault.shared {
            members += vault.members
        }

        return members
    }

    var itemIsLinkToVault: Bool {
        vault?.vault.isVaultRepresentation ?? false
    }

    weak var delegate: (any ItemDetailViewModelDelegate)?
    var cancellables = Set<AnyCancellable>()

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         upgradeChecker: any UpgradeCheckerProtocol) {
        self.isShownAsSheet = isShownAsSheet
        self.itemContent = itemContent
        customFieldUiModels = itemContent.customFields.map { .init(customField: $0) }
        self.upgradeChecker = upgradeChecker

        vault = appContentManager.getShareContent(for: itemContent.shareId)?.toVaultListUiModel

        bindValues()
        checkIfFreeUser()
        getPassUserInfos()
        addItemReadEvent(itemContent)
        assert(superBindValuesCalled, "bindValues must be overridden with call to super")
    }

    /// To be overidden with super call by subclasses
    func bindValues() {
        isMonitored = !itemContent.item.monitoringDisabled
        superBindValuesCalled = true
    }

    /// Copy to clipboard and trigger a toast message
    /// - Parameters:
    ///    - text: The text to be copied to clipboard.
    ///    - message: The message of the toast (e.g. "Note copied", "Alias copied")
    func copyToClipboard(text: String, message: String) {
        donateToItemForceTouchTip()
        router.action(.copyToClipboard(text: text, message: message))
    }

    func goBack() {
        delegate?.itemDetailViewModelWantsToGoBack(isShownAsSheet: isShownAsSheet)
    }

    func edit() {
        donateToItemForceTouchTip()
        delegate?.itemDetailViewModelWantsToEditItem(itemContent)
    }

    func share() {
        guard let vault, vault.vault.shareRole != .read else { return }
        router.present(for: .shareVaultFromItemDetail(vault, itemContent))
    }

    func fetchAttachments() async {
        guard fileAttachmentsEnabled, itemContent.item.hasFiles, let share = vault?.vault else { return }
        do {
            if files.isError {
                files = .fetching
            }
            let userId = try await userManager.getActiveUserId()
            let files = try await fileRepository.getActiveItemFiles(userId: userId,
                                                                    item: itemContent,
                                                                    share: share)
            self.files = .fetched(files)
        } catch {
            files = .error(error)
            logger.error(error)
        }
    }

    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let shareId = itemContent.shareId
                let itemId = itemContent.item.itemID
                guard let updatedItemContent =
                    try await itemRepository.getItemContent(shareId: shareId,
                                                            itemId: itemId) else {
                    return
                }
                itemContent = updatedItemContent
                bindValues()
                await fetchAttachments()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func showLarge(_ data: FullScreenData) {
        delegate?.itemDetailViewModelWantsToShowFullScreen(data)
    }

    func moveToAnotherVault() {
        router.present(for: .moveItemsBetweenVaults(.singleItem(itemContent)))
    }

    func toggleItemPinning() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("beginning of pin/unpin of \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                if itemContent.item.pinned {
                    try await unpinItems([itemContent])
                } else {
                    try await pinItems([itemContent])
                }
                let message = itemContent.item.pinned ?
                    #localized("Item successfully unpinned") : #localized("Item successfully pinned")
                router.display(element: .successMessage(message, config: .refresh))
                logger.trace("Success of pin/unpin of \(itemContent.debugDescription)")
                donateToItemForceTouchTip()
            } catch {
                handle(error)
            }
        }
    }

    func toggleMonitoring() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Toggling monitor from \(isMonitored) for \(itemContent.debugDescription)")
                router.display(element: .globalLoading(shouldShow: true))
                try await toggleItemMonitoring(item: itemContent, shouldNotMonitor: isMonitored)
                logger.trace("Toggled monitor to \(!isMonitored) for \(itemContent.debugDescription)")
                if isMonitored {
                    let message = #localized("Item excluded from monitoring")
                    router.display(element: .infosMessage(message))
                } else {
                    let message = #localized("Item included for monitoring")
                    router.display(element: .successMessage(message))
                }
                refresh()
            } catch {
                handle(error)
            }
        }
    }

    func copyNoteContent() {
        guard itemContent.type == .note else {
            assertionFailure("Only applicable to note item")
            return
        }
        copyToClipboard(text: itemContent.note, message: #localized("Note content copied"))
    }

    func clone() {
        router.present(for: .cloneItem(itemContent))
    }

    func moveToTrash() {
        itemContextMenuHandler.trash(itemContent)
    }

    func restore() {
        itemContextMenuHandler.restore(itemContent)
    }

    // Overridden by alias detail page
    func disableAlias() {}

    func permanentlyDelete() {
        itemContextMenuHandler.deletePermanently(itemContent)
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func getSymmetricKey() async throws -> SymmetricKey {
        try await symmetricKeyProvider.getSymmetricKey()
    }

    func showItemHistory() {
        router.present(for: .history(itemContent))
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }

    func leaveShare() {
        guard let share = vault?.vault else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let userId = try await userManager.getActiveUserId()
                try await leaveShareUsecase(userId: userId, with: share.shareId)
                syncEventLoop.forceSync()
                router.action(.screenDismissal(.all))
            } catch {
                handle(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension BaseItemDetailViewModel {
    func checkIfFreeUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                handle(error)
            }
        }
    }

    func donateToItemForceTouchTip() {
        Task {
            guard #available(iOS 17, *) else { return }
            await ItemForceTouchTip.didPerformEligibleQuickAction.donate()
        }
    }

    func getPassUserInfos() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                let passUserInfos = try await accessRepository.getPassUserInformation(userId: userId)
                guard let vault else { return }
                canDisplayFeatureDiscovery = passUserInfos.canDisplayFeatureDiscovery && itemSharingEnabled && vault.vault.shareRole != .read
            } catch {
                handle(error)
            }
        }
    }
}

extension BaseItemDetailViewModel: FileAttachmentsViewHandler {
    var fileAttachmentsSectionPrimaryColor: UIColor {
        itemContent.type.normMajor2Color
    }

    var fileAttachmentsSectionSecondaryColor: UIColor {
        itemContent.type.normMinor1Color
    }

    var itemContentType: ItemContentType {
        itemContent.type
    }

    func retryFetchingAttachments() {
        Task { [weak self] in
            guard let self else { return }
            await fetchAttachments()
        }
    }

    func open(_ file: FileAttachmentUiModel) {
        openPreview(file, postAction: .none)
    }

    func save(_ file: FileAttachmentUiModel) {
        openPreview(file, postAction: .save)
    }

    func share(_ file: FileAttachmentUiModel) {
        openPreview(file, postAction: .share)
    }
}

private extension BaseItemDetailViewModel {
    func openPreview(_ file: FileAttachmentUiModel,
                     postAction: FileAttachmentPreviewPostDownloadAction) {
        Task {
            do {
                guard case let .fetched(files) = files else {
                    throw PassError.fileAttachment(.failedToDownloadNoFetchedFiles)
                }
                guard let file = files.first(where: { $0.fileID == file.id }) else {
                    throw PassError.fileAttachment(.missingFile(file.id))
                }

                let userId = try await userManager.getActiveUserId()
                let url = try generateFileTempUrl(userId: userId,
                                                  item: itemContent,
                                                  file: file)
                if FileManager.default.fileExists(atPath: url.path()) {
                    // File already downloaded => open directly
                    switch postAction {
                    case .save:
                        urlToSave = url
                    case .share:
                        urlToShare = url
                    case .none:
                        filePreviewMode = .item(file, self, postAction)
                    }
                } else {
                    // File not downloaded => open preview page to download
                    filePreviewMode = .item(file, self, postAction)
                }
            } catch {
                handle(error)
            }
        }
    }
}

extension BaseItemDetailViewModel: FileAttachmentPreviewHandler {
    func downloadAndDecrypt(file: ItemFile) async throws
        -> AsyncThrowingStream<ProgressEvent<URL>, any Error> {
        let userId = try await userManager.getActiveUserId()
        return try await downloadAndDecryptFile(userId: userId,
                                                item: itemContent,
                                                file: file)
    }
}
