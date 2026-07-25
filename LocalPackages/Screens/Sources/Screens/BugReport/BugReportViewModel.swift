//
// BugReportViewModel.swift
// Proton Pass - Created on 28/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import DIComposition
import Entities
import FactoryKit
import Foundation
import Macro
import PhotosUI
import SwiftUI

enum BugReportObject: CaseIterable {
    case autofill, autosave, aliases, syncing, featureRequest, other

    var description: String {
        switch self {
        case .autofill:
            #localized("AutoFill")

        case .autosave:
            #localized("Autosave")

        case .aliases:
            #localized("Aliases")

        case .syncing:
            #localized("Syncing")

        case .featureRequest:
            #localized("Feature request")

        case .other:
            #localized("Other")
        }
    }
}

@MainActor
final class BugReportViewModel: ObservableObject {
    @Published var object: BugReportObject?
    @Published var description = ""
    @Published private(set) var hasSent = false
    @Published private(set) var actionInProcess = false
    @Published var shouldSendLogs = true
    @Published var selectedPhotos = [PhotosPickerItem]()

    private let accessRepository = dependency(\RepositoryContainer.accessRepository)
    private let sendUserBugReport = dependency(\UseCasesContainer.sendUserBugReport)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    private let logManager = dependency(\ToolingContainer.logManager)
    private let logger: Logger

    private var cancellable = Set<AnyCancellable>()

    @Published private(set) var currentFiles = [String: URL]()

    init() {
        logger = .init(manager: logManager)
        $selectedPhotos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photos in
                guard let self else {
                    return
                }
                addPhotos(photos)
            }
            .store(in: &cancellable)
    }

    func send() {
        Task { [weak self] in
            guard let self else { return }
            actionInProcess = true
            defer { actionInProcess = false }
            do {
                let object = try validate()
                let plan = try await accessRepository.getPlan(userId: nil)
                let planName = plan.type.capitalized
                let title = "[\(planName)] iOS Proton Pass: \(object.description)"
                if try await sendUserBugReport(with: title,
                                               and: description,
                                               shouldSendLogs: shouldSendLogs,
                                               otherLogContent: currentFiles.nilIfEmpty) {
                    hasSent = true
                } else {
                    throw PassError.bugReport(.failedToSend)
                }
            } catch {
                handle(error)
            }
        }
    }

    func addFiles(_ files: Result<[URL], any Error>) {
        switch files {
        case let .success(fileUrls):
            let maxFileSizeInMb = Constants.Report.maxFileSizeInMb
            let maxFileSizeInBytes = maxFileSizeInMb * 1_024 * 1_024
            do {
                var hasLargeFiles = false
                for fileUrl in fileUrls {
                    _ = fileUrl.startAccessingSecurityScopedResource()
                    defer { fileUrl.stopAccessingSecurityScopedResource() }
                    let fileSize = try fileUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard fileSize <= maxFileSizeInBytes else {
                        hasLargeFiles = true
                        continue
                    }

                    let maxFileCount = Constants.Report.maxFileCount
                    if currentFiles.count == maxFileCount {
                        throw PassError.bugReport(.tooManyFiles(maxFileCount: maxFileCount))
                    }
                    currentFiles[fileUrl.lastPathComponent] = try fileUrl.copyFileToTempDirectory()
                }

                if hasLargeFiles {
                    throw PassError.bugReport(.fileTooLarge(maxSizeInMb: maxFileSizeInMb))
                }
            } catch {
                handle(error)
            }

        case let .failure(error):
            handle(error)
        }
    }

    func removeFile(_ name: String) {
        currentFiles.removeValue(forKey: name)
    }
}

private extension BugReportViewModel {
    func addPhotos(_ photos: [PhotosPickerItem]) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                actionInProcess = false
            }
            do {
                actionInProcess = true
                for key in currentFiles.keys where key.contains("Screenshot -") {
                    currentFiles.removeValue(forKey: key)
                }
                let data = try await fetchContentUrls(photos)
                currentFiles = currentFiles.merging(data) { _, new in new }
            } catch {
                handle(error)
            }
        }
    }

    func fetchContentUrls(_ photos: [PhotosPickerItem]) async throws -> [String: URL] {
        try await withThrowingTaskGroup(of: TempDirectoryTransferableUrl?.self,
                                        returning: [String: URL].self) { group in
            for photo in photos {
                group.addTask {
                    try await photo.loadTransferable(type: TempDirectoryTransferableUrl.self)
                }
            }

            var contentUrls: [String: URL] = [:]

            for try await url in group {
                if let url {
                    contentUrls["Screenshot - \(url.value.lastPathComponent)"] = url.value
                }
            }

            return contentUrls
        }
    }

    func validate() throws -> BugReportObject {
        guard let object else {
            throw PassError.bugReport(.missingReason)
        }

        if description.count < Constants.Report.minCharCount {
            throw PassError.bugReport(.shortDescription)
        }

        if description.count > Constants.Report.maxCharCount {
            throw PassError.bugReport(.longDescription(maxCharCount: Constants.Report.maxCharCount))
        }

        return object
    }

    func handle(_ error: any Error) {
        logger.error(error)

        let message = if let passError = error as? PassError,
                         case let .bugReport(reason) = passError {
            reason.localizedMessage
        } else {
            error.localizedDescription
        }
        router.display(element: .errorMessage(message))
    }
}

private extension PassError.BugReportFailureReason {
    var localizedMessage: String {
        switch self {
        case .missingReason:
            #localized("Please select a reason", bundle: .module)

        case .shortDescription:
            #localized("Please provide us with more details in the description", bundle: .module)

        case let .longDescription(limit):
            #localized("Description is too long. Please keep it under %lld characters.",
                       bundle: .module, limit)

        case let .tooManyFiles(maxFileCount):
            #localized("Please limit your selection to %lld files", bundle: .module, maxFileCount)

        case let .fileTooLarge(maxFileSizeInMb):
            #localized("One or more files exceed the %lld MB limit. Please select smaller files.",
                       bundle: .module, maxFileSizeInMb)

        case .failedToSend:
            #localized("Failed to send report", bundle: .module)
        }
    }
}
