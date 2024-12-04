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
            file.id
        }
    }

    public var toUiModel: FileAttachmentUiModel {
        switch self {
        case let .pending(item):
            .init(id: item.id,
                  url: item.metadata.url,
                  state: item.uploadState,
                  name: item.metadata.name,
                  group: item.metadata.fileGroup,
                  formattedSize: item.metadata.formattedSize)
        case let .item(item):
            .init(id: item.id,
                  url: nil,
                  state: .uploaded(remoteId: item.id),
                  name: "",
                  group: .unknown,
                  formattedSize: nil)
        }
    }
}

public enum FileAttachmentUploadState: Sendable, Equatable {
    case uploading
    /// `remoteID` is given by the BE after uploading
    case uploaded(remoteId: String)
    case error(any Error)

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.uploading, .uploading):
            true
        case let (.uploaded(lId), .uploaded(rId)):
            lId == rId
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

    public var remoteId: String? {
        if case let .uploaded(remoteId) = self {
            remoteId
        } else {
            nil
        }
    }
}

public struct FileAttachmentUiModel: Sendable, Equatable, Identifiable {
    public let id: String
    /// Local URL to the file
    public let url: URL?
    public let state: FileAttachmentUploadState
    public let name: String
    public let group: FileGroup
    public let formattedSize: String?
}

public extension [FileAttachment] {
    mutating func updateState(id: String, newState: FileAttachmentUploadState) {
        guard let index = self.firstIndex(where: { $0.id == id }) else { return }
        let file = self[index]
        switch file {
        case var .pending(pendingFile):
            pendingFile.update(newState)
            self[index] = .pending(pendingFile)
        case .item:
            // Not applicable
            return
        }
    }
}
