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
import XCTest

final class PlanTests: XCTestCase {
    func testPlanType() {
        // Plus
        let plusPlan = Plan(type: "plus",
                            internalName: "test",
                            displayName: "test",
                            hideUpgrade: false,
                            manageAlias: false,
                            trialEnd: nil,
                            vaultLimit: nil,
                            aliasLimit: nil,
                            totpLimit: nil,
                            storageAllowed: true,
                            storageUsed: 1,
                            storageQuota: 2)
        XCTAssertEqual(plusPlan.planType, .plus)

        // Free
        let freePlan = Plan(type: "free",
                            internalName: "test",
                            displayName: "test",
                            hideUpgrade: false,
                            manageAlias: false,
                            trialEnd: nil,
                            vaultLimit: nil,
                            aliasLimit: nil,
                            totpLimit: nil,
                            storageAllowed: false,
                            storageUsed: 1,
                            storageQuota: 2)
        XCTAssertEqual(freePlan.planType, .free)

        // Trial
        let trialPlan = Plan(type: "plus",
                             internalName: "test",
                             displayName: "test",
                             hideUpgrade: false,
                             manageAlias: false,
                             trialEnd: .random(in: 1...1_000),
                             vaultLimit: nil,
                             aliasLimit: nil,
                             totpLimit: nil,
                             storageAllowed: false,
                             storageUsed: 1,
                             storageQuota: 2)
        XCTAssertEqual(trialPlan.planType, .trial)
    }
}
