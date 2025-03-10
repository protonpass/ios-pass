//
// FileAttachment.swift
// Proton Pass - Created on 03/12/2024.
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

import Foundation

public enum FileAttachment: Sendable, Equatable, Identifiable {
    case pending(PendingFileAttachment)
    case item(ItemFile)

    public var id: String {
        switch self {
        case let .pending(file):
            file.id
        case let .item(file):
            file.fileID
        }
    }
}

public enum FileAttachmentUploadState: Sendable, Equatable {
    /// Upload progress as associated value. From 0.0 to 1.0
    case uploading(Float)
    case uploaded
    case error(any Error)

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.uploaded, .uploaded):
            true
        case let (.uploading(lProgress), .uploading(rProgress)):
            lProgress == rProgress
        case let (.error(lError), .error(rError)):
            lError.localizedDescription == rError.localizedDescription
        default:
            false
        }
    }

    public var isError: Bool {
        if case .error = self {
            true
        } else {
            false
        }
    }
}

public struct FileAttachmentUiModel: Sendable, Equatable, Identifiable {
    public let id: String
    public let persistentFileUID: String?
    /// Local URL to the file
    public let url: URL?
    public let state: FileAttachmentUploadState
    public let name: String
    public let group: FileGroup
    public let formattedSize: String?

    public init(id: String,
                persistentFileUID: String?,
                url: URL?,
                state: FileAttachmentUploadState,
                name: String,
                group: FileGroup,
                formattedSize: String?) {
        self.id = id
        self.persistentFileUID = persistentFileUID
        self.url = url
        self.state = state
        self.name = name
        self.group = group
        self.formattedSize = formattedSize
    }
}

public extension [FileAttachment] {
    mutating func upsert(_ file: PendingFileAttachment) {
        if let index = firstIndex(where: { $0.id == file.id }) {
            self[index] = .pending(file)
        } else {
            append(.pending(file))
        }
    }

    mutating func upsert(_ file: ItemFile) {
        if let index = firstIndex(where: { $0.id == file.fileID }) {
            self[index] = .item(file)
        } else {
            append(.item(file))
        }
    }
}
