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
import Factory
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

struct DataUrl: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .data) { data in
            SentTransferredFile(data.url)
        } importing: { received in
            let copy = try received.file.copyFileToTempFolder()
            return Self(url: copy)
        }
    }
}

@MainActor
final class BugReportViewModel: ObservableObject {
    @Published var object: BugReportObject?
    @Published var description = ""
    @Published private(set) var error: Error?
    @Published private(set) var hasSent = false
    @Published private(set) var actionInProcess = false
    @Published var shouldSendLogs = true
    @Published var selectedContent = [PhotosPickerItem]()

    var cantSend: Bool { object == nil || description.count < 10 }

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let sendUserBugReport = resolve(\UseCasesContainer.sendUserBugReport)
    private var cancellable = Set<AnyCancellable>()

    @Published private(set) var currentFiles = [String: URL]()

    enum SendError: Error {
        case failedToSendReport
    }

    init() {
        $selectedContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                guard let self else {
                    return
                }
                addContent(content: content)
            }.store(in: &cancellable)
    }

    func send() {
        assert(object != nil, "An object must be selected")
        Task { @MainActor [weak self] in
            guard let self else { return }
            actionInProcess = true
            do {
                let plan = try await accessRepository.getPlan()
                let planName = plan.type.capitalized
                let objectDescription = object?.description ?? ""
                let title = "[\(planName)] iOS Proton Pass: \(objectDescription)"
                if try await sendUserBugReport(with: title,
                                               and: description,
                                               shouldSendLogs: shouldSendLogs,
                                               otherLogContent: currentFiles.isEmpty ? nil : currentFiles) {
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

    func addFiles(files: Result<[URL], Error>) {
        switch files {
        case let .success(fileUrls):
            do {
                for fileUrl in fileUrls {
                    _ = fileUrl.startAccessingSecurityScopedResource()
                    currentFiles[fileUrl.lastPathComponent] = try fileUrl.copyFileToTempFolder()
                    fileUrl.stopAccessingSecurityScopedResource()
                }
            } catch {
                self.error = error
            }
        case let .failure(error):
            self.error = error
        }
    }

    func clearAllAddedFiles() {
        currentFiles.removeAll()
        selectedContent.removeAll()
    }
}

private extension BugReportViewModel {
    func addContent(content: [PhotosPickerItem]) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                actionInProcess = false
            }
            do {
                actionInProcess = true
                for key in currentFiles.keys where key.contains("Content -") {
                    currentFiles.removeValue(forKey: key)
                }
                let data = try await fetchContentUrls(content: content)
                currentFiles = currentFiles.merging(data) { _, new in new }
            } catch {
                self.error = error
            }
        }
    }

    func fetchContentUrls(content: [PhotosPickerItem]) async throws -> [String: URL] {
        try await withThrowingTaskGroup(of: DataUrl?.self, returning: [String: URL].self) { group in
            for item in content {
                group.addTask { try await item.loadTransferable(type: DataUrl.self) }
            }

            var contentUrls: [String: URL] = [:]

            for try await result in group {
                if let result {
                    contentUrls["Content - \(result.url.lastPathComponent)"] = result.url
                }
            }

            return contentUrls
        }
    }
}
