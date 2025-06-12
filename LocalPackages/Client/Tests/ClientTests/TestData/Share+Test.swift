//
// Share+Test.swift
// Proton Pass - Created on 03/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

@testable import Client
import Entities

extension Share {
    static func random(shareId: String? = nil,
                       vaultId: String? = nil,
                       contentKeyRotation: Int64? = nil) -> Share {
        .init(shareID: shareId ?? .random(),
              vaultID: vaultId ?? .random(),
              addressID: .random(),
              targetType: .random(in: 0...10),
              targetID: .random(),
              permission: .random(in: 0...10),
              shareRoleID: "1",
              targetMembers: .random(in: 0...10),
              targetMaxMembers: .random(in: 0...10), 
              pendingInvites: .random(in: 0...4),
              newUserInvitesReady: .random(in: 0...5),
              owner: .random(),
              shared: true,
              content: .random(),
              contentKeyRotation: contentKeyRotation ?? .random(in: 0...10),
              contentFormatVersion: .random(in: 0...10),
              expireTime: .random(in: 0...1_000_000),
              createTime: .random(in: 0...1_000_000),
              canAutoFill: .random(),
              hidden: .random())
    }
}
