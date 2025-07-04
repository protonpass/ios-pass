//
//
// DetailHistoryViewModel.swift
// Proton Pass - Created on 11/01/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Client
import Combine
import Entities
import FactoryKit
import Foundation
import Macro
import Screens
import UIKit

enum SelectedRevision {
    case current, past
}

@MainActor
final class DetailHistoryViewModel: ObservableObject {
    @Published var selectedItemIndex = 0
    @Published private(set) var restoringItem = false
    @Published private(set) var selectedRevision: SelectedRevision = .past
    @Published var filePreviewMode: FileAttachmentPreviewMode?
    @Published var urlToSave: URL?
    @Published var urlToShare: URL?

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    @LazyInjected(\SharedRepositoryContainer.fileAttachmentRepository) private var fileAttachmentRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedUseCasesContainer.formatFileAttachmentSize) private var formatFileAttachmentSize
    @LazyInjected(\SharedUseCasesContainer.getFileGroup) private var getFileGroup
    @LazyInjected(\SharedUseCasesContainer.generateFileTempUrl) private var generateFileTempUrl
    @LazyInjected(\SharedUseCasesContainer.downloadAndDecryptFile) private var downloadAndDecryptFile

    private var cancellables = Set<AnyCancellable>()

    let totpManager = resolve(\SharedServiceContainer.totpManager)
    let currentRevision: ItemContent
    let pastRevision: ItemContent
    let files: [ItemFile]

    private var currentFiles: [FileAttachmentUiModel] {
        filterFiles(for: currentRevision)
    }

    private var pastFiles: [FileAttachmentUiModel] {
        filterFiles(for: pastRevision)
    }

    var hasFileDifferences: Bool {
        Set(currentFiles.map(\.id)) != Set(pastFiles.map(\.id))
    }

    var selectedRevisionContent: ItemContent {
        switch selectedRevision {
        case .past:
            pastRevision
        case .current:
            currentRevision
        }
    }

    init(currentRevision: ItemContent,
         pastRevision: ItemContent,
         files: [ItemFile]) {
        self.currentRevision = currentRevision
        self.pastRevision = pastRevision
        self.files = files
        setUp()
    }

    func fileUiModels(for item: ItemContent) -> [FileAttachmentUiModel] {
        item.item.revision == currentRevision.item.revision ? currentFiles : pastFiles
    }
}

// MARK: Common operations

extension DetailHistoryViewModel {
    func isDifferent(for element: KeyPath<ItemContent, some Hashable>) -> Bool {
        currentRevision[keyPath: element] != pastRevision[keyPath: element]
    }

    func viewPasskey(_ passkey: Passkey) {
        router.present(for: .passkeyDetail(passkey))
    }

    func restore() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                restoringItem = false
            }
            restoringItem = true
            do {
                let userId = try await userManager.getActiveUserId()
                let protobuff = ItemContentProtobuf(name: pastRevision.name,
                                                    note: pastRevision.note,
                                                    itemUuid: pastRevision.itemUuid,
                                                    data: pastRevision.contentData,
                                                    customFields: pastRevision.customFields)
                let updatedItem = try await itemRepository.updateItem(userId: userId,
                                                                      oldItem: currentRevision.item,
                                                                      newItemContent: protobuff,
                                                                      shareId: currentRevision.shareId)

                let currentFileIds = currentFiles.compactMapToSet(\.persistentFileUID)
                let pastFileIds = pastFiles.compactMapToSet(\.persistentFileUID)

                let persistentIdsToRemove = Array(currentFileIds.subtracting(pastFileIds))
                let persistentIdsToRestore = pastFileIds.subtracting(currentFileIds)

                let fileIdsToRemove = files.compactMap { file -> String? in
                    persistentIdsToRemove.contains(file.persistentFileUID) ? file.fileID : nil
                }
                let filesToRestore = files.filter { persistentIdsToRestore.contains($0.persistentFileUID) }

                try await fileAttachmentRepository.linkFilesToItem(userId: userId,
                                                                   pendingFilesToAdd: [],
                                                                   existingFileIdsToRemove: fileIdsToRemove,
                                                                   item: updatedItem)
                try await fileAttachmentRepository.restoreFiles(userId: userId,
                                                                item: updatedItem,
                                                                files: filesToRestore)

                router.present(for: .restoreHistory)
            } catch {
                handle(error)
            }
        }
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

// MARK: Copy functions

extension DetailHistoryViewModel {
    func copyValueToClipboard(value: String, message: String) {
        router.action(.copyToClipboard(text: value, message: #localized("%@ copied", message)))
    }

    func copyAlias() {
        copy(\.aliasEmail, message: #localized("Alias copied"))
    }

    func copyEmail() {
        copy(\.loginItem?.email, message: #localized("Email address copied"))
    }

    func copyItemUsername() {
        copy(\.loginItem?.username, message: #localized("Username copied"))
    }

    func copyPassword() {
        copy(\.loginItem?.password, message: #localized("Password copied"))
    }

    func copyTotpToken(_ token: String) {
        copy(token, message: #localized("TOTP copied"))
    }

    func copyCardholderName() {
        copy(\.creditCardItem?.cardholderName, message: #localized("Cardholder name copied"))
    }

    func copyCardNumber() {
        copy(\.creditCardItem?.number, message: #localized("Card number copied"))
    }

    func copyExpirationDate() {
        copy(\.creditCardItem?.displayedExpirationDate, message: #localized("Expiration date copied"))
    }

    func copySecurityCode() {
        copy(\.creditCardItem?.verificationNumber, message: #localized("Security code copied"))
    }

    func copyWifiSsid() {
        copy(\.wifi?.ssid, message: #localized("SSID copied"))
    }

    func copyWifiPassword() {
        copy(\.wifi?.password, message: #localized("WiFi password copied"))
    }
}

// MARK: Private APIs

private extension DetailHistoryViewModel {
    func setUp() {
        $selectedItemIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self else {
                    return
                }
                selectedRevision = index == 0 ? .past : .current

                if let totpUri = selectedRevisionContent.loginItem?.totpUri {
                    totpManager.bind(uri: totpUri)
                }
            }
            .store(in: &cancellables)
    }

    /// Copy the text to clipboard if it's not empty and show a toast message
    func copy(_ text: String?, message: String) {
        if let text, !text.isEmpty {
            router.action(.copyToClipboard(text: text, message: message))
        }
    }

    func copy(_ keypath: KeyPath<ItemContent, String?>, message: String) {
        copy(selectedRevisionContent[keyPath: keypath], message: message)
    }
}

extension DetailHistoryViewModel: FileAttachmentsViewHandler {
    var fileAttachmentsSectionPrimaryColor: UIColor {
        itemContentType.normMajor2Color
    }

    var fileAttachmentsSectionSecondaryColor: UIColor {
        itemContentType.normMinor1Color
    }

    var itemContentType: ItemContentType {
        currentRevision.type
    }

    func retryFetchingAttachments() {
        // Not applicable
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

private extension DetailHistoryViewModel {
    func filterFiles(for item: ItemContent) -> [FileAttachmentUiModel] {
        files.compactMap { file in
            let eligible = if let revisionRemoved = file.revisionRemoved {
                revisionRemoved > item.item.revision
            } else {
                file.revisionAdded <= item.item.revision
            }

            guard eligible else { return nil }

            guard let name = file.name,
                  let mimeType = file.mimeType else {
                assertionFailure("Missing file name and MIME type")
                return nil
            }

            let formattedSize = formatFileAttachmentSize(file.size)
            let fileGroup = getFileGroup(mimeType: mimeType)
            return .init(id: file.fileID,
                         persistentFileUID: file.persistentFileUID,
                         url: nil,
                         state: .uploaded,
                         name: name,
                         group: fileGroup,
                         formattedSize: formattedSize)
        }
    }

    func openPreview(_ file: FileAttachmentUiModel,
                     postAction: FileAttachmentPreviewPostDownloadAction) {
        Task {
            do {
                guard let file = files.first(where: { $0.fileID == file.id }) else {
                    throw PassError.fileAttachment(.missingFile(file.id))
                }

                let userId = try await userManager.getActiveUserId()
                let url = try generateFileTempUrl(userId: userId,
                                                  item: selectedRevisionContent,
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

extension DetailHistoryViewModel: FileAttachmentPreviewHandler {
    func downloadAndDecrypt(file: ItemFile) async throws
        -> AsyncThrowingStream<ProgressEvent<URL>, any Error> {
        let userId = try await userManager.getActiveUserId()
        return try await downloadAndDecryptFile(userId: userId,
                                                item: selectedRevisionContent,
                                                file: file)
    }
}
