//
// GetFilesToLinkTests.swift
// Proton Pass - Created on 10/12/2024.
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
import EntitiesMocks
import Foundation
import Testing
import UseCases

struct GetFilesToLinkTests {
    let sut: any GetFilesToLinkUseCase

    init() {
        sut = GetFilesToLink()
    }

    @Test("Get file to add and remove")
    func get() {
        // Given
        let attachedFiles: [ItemFile] = [
            .random(fileID: "attached_0"),
            .random(fileID: "attached_1"),
            .random(fileID: "attached_2"),
            .random(fileID: "attached_3"),
            .random(fileID: "attached_4")
        ]

        let updatedFiles: [FileAttachment] = [
            .pending(.random(id: "pending_0")),
            .item(.random(fileID: "attached_0")),
            .pending(.random(id: "pending_1")),
            .item(.random(fileID: "attached_3"))
        ]

        // When
        let filesToLink = sut(attachedFiles: attachedFiles, updatedFiles: updatedFiles)

        // Then
        #expect(filesToLink.toAdd.count == 2)
        #expect(filesToLink.toAdd.contains(where: { $0.id == "pending_0" }))
        #expect(filesToLink.toAdd.contains(where: { $0.id == "pending_1" }))
        #expect(filesToLink.toRemove.count == 3)
        #expect(filesToLink.toRemove.contains(where: { $0 == "attached_1" }))
        #expect(filesToLink.toRemove.contains(where: { $0 == "attached_2" }))
        #expect(filesToLink.toRemove.contains(where: { $0 == "attached_4" }))
    }
}
