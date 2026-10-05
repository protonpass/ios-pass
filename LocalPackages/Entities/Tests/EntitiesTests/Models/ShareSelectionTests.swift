//
// ShareSelectionTests.swift
// Proton Pass - Created on 05/10/2026.
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

import Entities
import EntitiesMocks
import Testing

@Suite(.tags(.entity))
struct ShareSelectionTests {
    @Test func `selections of the same share are equal and hash alike even when share details differ`() {
        let share = Share.random(shareID: "share-1", targetType: 1, targetMembers: 1)
        let updatedShare = Share.random(shareID: "share-1", targetType: 1, targetMembers: 5)
        let selection = ShareSelection.precise(.init(share: share, folder: nil))
        let updatedSelection = ShareSelection.precise(.init(share: updatedShare, folder: nil))

        #expect(selection == updatedSelection)
        #expect(selection.hashValue == updatedSelection.hashValue)
        #expect(Set([selection, updatedSelection]).count == 1)
    }

    @Test func `a folder selection differs from its vault selection`() {
        let share = Share.random(shareID: "share-1", targetType: 1)
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: "share-1")

        #expect(ShareSelection.precise(.init(share: share, folder: folder))
            != ShareSelection.precise(.init(share: share, folder: nil)))
    }

    @Test func `fixed selections are distinct from each other`() {
        let selections: [ShareSelection] = [.all, .sharedWithMe, .sharedByMe, .trash]
        #expect(Set(selections).count == selections.count)
    }
}
