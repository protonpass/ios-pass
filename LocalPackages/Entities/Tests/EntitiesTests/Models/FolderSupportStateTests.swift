//
// FolderSupportStateTests.swift
// Proton Pass - Created on 17/09/2026.
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
struct FolderSupportStateTests {
    @Test("Folders are unsupported while the flag is off, whatever the plan allows",
          arguments: [true, false])
    func flagOff(folderAllowed: Bool) {
        let sut = FolderSupportState(flagEnabled: false,
                                     plan: .mock(type: "plus", folderAllowed: folderAllowed))

        #expect(!sut.isSupported)
        #expect(!sut.canCreateAndModifyFolders)
        #expect(!sut.shouldUpsell)
    }

    @Test("A not yet loaded plan grants nothing")
    func missingPlan() {
        let sut = FolderSupportState(flagEnabled: true, plan: nil)

        #expect(!sut.isSupported)
        #expect(!sut.canCreateAndModifyFolders)
        #expect(!sut.shouldUpsell)
    }

    @Test("Plan drives support once the flag is on", arguments: [
        ("plus", true, true, false),
        ("free", false, false, true),
        ("business", false, false, false)
    ])
    func flagOn(type: String,
                folderAllowed: Bool,
                canCreateAndModifyFolders: Bool,
                shouldUpsell: Bool) {
        let sut = FolderSupportState(flagEnabled: true,
                                     plan: .mock(type: type,
                                                 trialEnd: 0,
                                                 folderAllowed: folderAllowed))

        #expect(sut.isSupported)
        #expect(sut.canCreateAndModifyFolders == canCreateAndModifyFolders)
        #expect(sut.shouldUpsell == shouldUpsell)
    }
}
