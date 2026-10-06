//
// OrganizationTests.swift
// Proton Pass - Created on 06/10/2026.
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
import Testing

@Suite(.tags(.entity))
struct OrganizationTests {
    @Test(arguments: [
        (canUpdate: true, exportMode: Organization.ExportMode.admins, expected: true),
        (canUpdate: false, exportMode: .admins, expected: false),
        (canUpdate: false, exportMode: .anyone, expected: true)
    ])
    func `export allowed for admins or when anyone can export`(canUpdate: Bool,
                                                              exportMode: Organization.ExportMode,
                                                              expected: Bool) {
        let settings = Organization.Settings(shareMode: .default,
                                             itemShareMode: .default,
                                             publicLinkMode: .default,
                                             forceLockSeconds: 0,
                                             exportMode: exportMode,
                                             passwordPolicy: nil,
                                             vaultCreateMode: nil,
                                             aliasCreateMode: nil)
        #expect(Organization(canUpdate: canUpdate, settings: settings).exportAllowed == expected)
    }

    @Test func `export not allowed for members when settings are missing`() {
        #expect(!Organization(canUpdate: false, settings: nil).exportAllowed)
    }
}
