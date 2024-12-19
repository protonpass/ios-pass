//
// GetFilesToLink.swift
// Friday the 13th
// Proton Pass - Created on 13/12/2024.
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

public struct FilesToLink: Sendable {
    public let toAdd: [PendingFileAttachment]
    public let toRemove: [String]

    public var isEmpty: Bool {
        toAdd.isEmpty && toRemove.isEmpty
    }
}

/// Compare the list of currently attached files and the edited one to detect which
/// ones to be added and removed
public protocol GetFilesToLinkUseCase: Sendable {
    func execute(attachedFiles: [ItemFile], updatedFiles: [FileAttachment]) -> FilesToLink
}

public extension GetFilesToLinkUseCase {
    func callAsFunction(attachedFiles: [ItemFile], updatedFiles: [FileAttachment]) -> FilesToLink {
        execute(attachedFiles: attachedFiles, updatedFiles: updatedFiles)
    }
}

public final class GetFilesToLink: GetFilesToLinkUseCase {
    public init() {}

    public func execute(attachedFiles: [ItemFile], updatedFiles: [FileAttachment]) -> FilesToLink {
        var toAdd = [PendingFileAttachment]()
        var preservedAttachedFileIds = Set<String>()

        for file in updatedFiles {
            switch file {
            case let .pending(pending):
                toAdd.append(pending)
            case let .item(attached):
                preservedAttachedFileIds.insert(attached.fileID)
            }
        }

        let allAttachedIds = Set(attachedFiles.map(\.fileID))
        let toRemove = Array(allAttachedIds.subtracting(preservedAttachedFileIds))
        return .init(toAdd: toAdd, toRemove: toRemove)
    }
}
