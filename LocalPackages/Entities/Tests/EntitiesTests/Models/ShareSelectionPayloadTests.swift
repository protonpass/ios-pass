//
// ShareSelectionPayloadTests.swift
// Proton Pass - Created on 16/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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

@testable import Entities
import EntitiesMocks
import Testing

@Suite(.tags(.entity))
struct ShareSelectionPayloadTests {
    @Test("Can create item", arguments: [
        (ShareRole.manager, false, false, true),
        (ShareRole.manager, true, false, false),
        (ShareRole.manager, true, true, true),
        (ShareRole.read, false, true, false)
    ])
    func canCreateItem(role: ShareRole,
                       folderSelected: Bool,
                       folderAllowed: Bool,
                       expectation: Bool) {
        let share = Share.random(targetType: 1, shareRoleID: role.rawValue)
        let folder = folderSelected ? FolderUiModel.mock(folderId: "folder-1", shareId: share.shareId) : nil
        let sut = ShareSelectionPayload(share: share, folder: folder)

        #expect(sut.canCreateItem(folderAllowed: folderAllowed) == expectation)
    }
}
