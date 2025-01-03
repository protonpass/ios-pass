//
// FileAttachmentPreviewModel.swift
// Proton Pass - Created on 23/12/2024.
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

import Entities
import Foundation

public protocol FileAttachmentPreviewHandler: Sendable {
    func downloadAndDecrypt(file: ItemFile,
                            progress: @Sendable @escaping (Float) -> Void) async throws -> URL
}

public enum FileAttachmentPreviewPostDownloadAction: String, Identifiable, Sendable {
    case none, save, share

    public var id: String { rawValue }
}

public enum FileAttachmentPreviewMode: Sendable, Identifiable {
    case pending(URL)
    case item(ItemFile,
              any FileAttachmentPreviewHandler,
              FileAttachmentPreviewPostDownloadAction)

    public var id: String {
        switch self {
        case let .pending(url):
            url.path()
        case let .item(item, _, _):
            item.fileID
        }
    }
}

@MainActor
final class FileAttachmentPreviewModel: ObservableObject {
    @Published private(set) var url: FetchableObject<URL> = .fetching
    @Published private(set) var progress: Float = 0.0
    @Published var urlToSave: URL?
    @Published var urlToShare: URL?
    private let mode: FileAttachmentPreviewMode

    var fileName: String? {
        if case let .item(itemFile, _, _) = mode {
            itemFile.name
        } else {
            nil
        }
    }

    init(mode: FileAttachmentPreviewMode) {
        self.mode = mode
    }
}

extension FileAttachmentPreviewModel {
    func fetchFile() async {
        switch mode {
        case let .pending(url):
            self.url = .fetched(url)

        case let .item(itemFile, handler, action):
            do {
                if url.isError {
                    url = .fetching
                }

                let url = try await handler.downloadAndDecrypt(file: itemFile) { [weak self] newProgress in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        // swiftformat:disable:next redundantSelf
                        self.progress = newProgress
                    }
                }
                self.url = .fetched(url)

                switch action {
                case .none:
                    break
                case .save:
                    urlToSave = url
                case .share:
                    urlToShare = url
                }
            } catch {
                url = .error(error)
            }
        }
    }
}
