//
// PlanTests.swift
// Proton Pass - Created on 22/05/2023.
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

@testable import Entities
import Testing

@Suite(.tags(.entity))
struct PlanTests {
    @Test func `plan type is derived from the type and trial end`() {
        #expect(plan(type: "plus", trialEnd: nil).planType == .plus)
        #expect(plan(type: "free", trialEnd: nil).planType == .free)
        #expect(plan(type: "plus", trialEnd: .random(in: 1...1_000)).planType == .trial)
    }
}

private extension PlanTests {
    func plan(type: String, trialEnd: Int?) -> Plan {
        Plan(type: type,
             internalName: "test",
             displayName: "test",
             hideUpgrade: false,
             manageAlias: false,
             trialEnd: trialEnd,
             vaultLimit: nil,
             aliasLimit: nil,
             totpLimit: nil,
             storageAllowed: false,
             storageUsed: 1,
             storageQuota: 2,
             folderAllowed: false,
             folderMaxCount: 5,
             folderMaxChildren: 5,
             folderMaxDepth: 5)
    }
}
