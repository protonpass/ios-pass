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
    @Published private(set) var error: (any Error)?
    @Published private(set) var hasSent = false
    @Published private(set) var actionInProcess = false
    @Published var shouldSendLogs = true
    @Published var selectedPhotos = [PhotosPickerItem]()

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let sendUserBugReport = resolve(\UseCasesContainer.sendUserBugReport)
    private var cancellable = Set<AnyCancellable>()

    @Published private(set) var currentFiles = [String: URL]()

    enum SendError: Error {
        case failedToSendReport
    }

    init() {
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
        assert(object != nil, "An object must be selected")
        Task { [weak self] in
            guard let self else { return }
            actionInProcess = true
            do {
                let plan = try await accessRepository.getPlan(userId: nil)
                let planName = plan.type.capitalized
                let objectDescription = object?.description ?? ""
                let title = "[\(planName)] iOS Proton Pass: \(objectDescription)"
                if try await sendUserBugReport(with: title,
                                               and: description,
                                               shouldSendLogs: shouldSendLogs,
                                               otherLogContent: currentFiles.nilIfEmpty) {
                    hasSent = true
                } else {
                    error = SendError.failedToSendReport
                }
            } catch {
                self.error = error
            }
            actionInProcess = false
        }
    }

    func addFiles(_ files: Result<[URL], any Error>) {
        switch files {
        case let .success(fileUrls):
            do {
                for fileUrl in fileUrls {
                    _ = fileUrl.startAccessingSecurityScopedResource()
                    currentFiles[fileUrl.lastPathComponent] = try fileUrl.copyFileToTempDirectory()
                    fileUrl.stopAccessingSecurityScopedResource()
                }
            } catch {
                self.error = error
            }
        case let .failure(error):
            self.error = error
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
                self.error = error
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
}
