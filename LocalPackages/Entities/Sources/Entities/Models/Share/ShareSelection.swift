//
// ShareSelection.swift
// Proton Pass - Created on 30/11/2023.
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

import Foundation

public struct ShareSelectionPayload: Hashable, Sendable {
    public let share: Share
    public let folder: FolderUiModel?

    public init(share: Share, folder: FolderUiModel?) {
        self.share = share
        self.folder = folder
    }

    public var isFolderSelected: Bool {
        folder != nil
    }

    public var title: String {
        folder?.content.name ?? share.vaultContent?.name ?? ""
    }

    public static var `default`: ShareSelectionPayload {
        .init(share: .default, folder: nil)
    }
}

public extension Share {
    static let `default` = Share(shareID: "",
                                 vaultID: "",
                                 addressID: "",
                                 targetType: 0,
                                 targetID: "",
                                 permission: 0,
                                 shareRoleID: "",
                                 targetMembers: 0,
                                 targetMaxMembers: 0,
                                 pendingInvites: 0,
                                 newUserInvitesReady: 0,
                                 owner: false,
                                 shared: false,
                                 content: nil,
                                 contentKeyRotation: nil,
                                 contentFormatVersion: nil,
                                 groupID: nil,
                                 expireTime: nil,
                                 createTime: 0,
                                 canAutoFill: false,
                                 flags: 0)
}

public enum ShareSelection: Hashable, Sendable {
    case all
    case precise(ShareSelectionPayload)
    case sharedWithMe
    case sharedByMe
    case trash

    public var shared: Bool {
        if case let .precise(selection) = self {
            return selection.share.shared
        }
        return false
    }

    public var selectedShareId: String? {
        if case let .precise(selection) = self {
            return selection.share.shareId
        }
        return nil
    }

    public var preciseSelectionPayload: ShareSelectionPayload? {
        switch self {
        case let .precise(selection): selection
        default: nil
        }
    }

    public var isFolderSelection: Bool {
        switch self {
        case let .precise(selection):
            selection.isFolderSelected
        default: false
        }
    }

//    public var preciseShare: Share? {
//        if case let .precise(share, _) = self {
//            return share
//        }
//        return nil
//    }

    public var preferenceKey: String? {
        switch self {
        case .all:
            nil
        case let .precise(selection):
            selection.share.shareId
        case .sharedWithMe:
            "sharedWithMe"
        case .sharedByMe:
            "sharedByMe"
        case .trash:
            "trash"
        }
    }

    public var isShared: Bool {
        switch self {
        case .sharedByMe, .sharedWithMe:
            true
        default:
            false
        }
    }
}

extension ShareSelection: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.preferenceKey == rhs.preferenceKey
    }
}
