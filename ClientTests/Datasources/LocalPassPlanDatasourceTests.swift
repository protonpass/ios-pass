//
// LocalPassPlanDatasourceTests.swift
// Proton Pass - Created on 04/05/2023.
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

@testable import Client
import XCTest

final class LocalPassPlanDatasourceTests: XCTestCase {
    var sut: LocalPassPlanDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalPassPlanDatasourceTests {
    func testUpsertAndGetPlans() async throws {
        // Given
        let givenUserId = String.random()
        let givenFreePlan = PassPlan.random(vaultLimit: .random(in: 1...100),
                                            aliasLimit: .random(in: 1...100),
                                            totpLimit: .random(in: 1...100))
        // When
        try await sut.upsert(passPlan: givenFreePlan, userId: givenUserId)
        let freePlan = try await sut.getPassPlan(userId: givenUserId)

        // Then
        XCTAssertEqual(freePlan, givenFreePlan)

        // Given
        let givenPaidPlan = PassPlan.random(vaultLimit: nil, aliasLimit: nil, totpLimit: nil)

        // When
        try await sut.upsert(passPlan: givenPaidPlan, userId: givenUserId)
        let paidPlan = try await sut.getPassPlan(userId: givenUserId)

        // Then
        XCTAssertEqual(paidPlan, givenPaidPlan)
    }
}

private extension PassPlan {
    static func random(vaultLimit: Int?, aliasLimit: Int?, totpLimit: Int?) -> PassPlan {
        .init(type: .random(),
              internalName: .random(),
              displayName: .random(),
              vaultLimit: vaultLimit,
              aliasLimit: aliasLimit,
              totpLimit: totpLimit)
    }
}
