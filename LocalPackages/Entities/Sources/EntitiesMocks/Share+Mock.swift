//
// Share+Mock.swift
// Proton Pass - Created on 28/11/2024.
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

import Entities

public extension Share {
    static func random(shareID: String? = nil,
                       vaultID: String? = nil,
                       addressID: String? = nil,
                       targetType: Int64 = 2,
                       targetID: String? = nil,
                       permission: Int64 = 0,
                       shareRoleID: String = "1",
                       targetMembers: Int64 = .random(in: 0...100),
                       targetMaxMembers: Int64 = .random(in: 0...100),
                       pendingInvites: Int64 = .random(in: 0...100),
                       newUserInvitesReady: Int64 = .random(in: 0...100),
                       owner: Bool = true,
                       shared: Bool = false,
                       content: String? = nil,
                       contentKeyRotation: Int64? = nil,
                       contentFormatVersion: Int64? = nil,
                       expireTime: Int64? = nil,
                       createTime: Int64 = .random(in: 0...100),
                       canAutoFill: Bool = true,
                       flags: Int = .random(in: 0...10)) -> Share {
        Share(shareID: shareID ?? .random(),
              vaultID: vaultID ?? .random(),
              addressID: addressID ?? .random(),
              targetType: targetType,
              targetID: targetID ?? .random(),
              permission: permission,
              shareRoleID: shareRoleID,
              targetMembers: targetMembers,
              targetMaxMembers: targetMaxMembers,
              pendingInvites: pendingInvites,
              newUserInvitesReady: newUserInvitesReady,
              owner: owner,
              shared: shared,
              content: content,
              contentKeyRotation: contentKeyRotation,
              contentFormatVersion: contentFormatVersion,
              expireTime: expireTime,
              createTime: createTime,
              canAutoFill: canAutoFill,
              flags: flags)
    }
}
