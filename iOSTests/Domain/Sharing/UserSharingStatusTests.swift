//
// UserSharingStatusTests.swift
// Proton Pass - Created on 25/07/2023.
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

import XCTest
@testable import Proton_Pass
@testable import Client

final class UserSharingStatusTests: XCTestCase {
    var sut: UserSharingStatusUseCase!
    var featureFlagsRepository: FeatureFlagsRepositoryProtocolMock!
    var passPlanRepository: PassPlanRepositoryProtocolMock!
    
    override func setUp() {
        super.setUp()
        featureFlagsRepository = FeatureFlagsRepositoryProtocolMock()
        passPlanRepository = PassPlanRepositoryProtocolMock()
        sut = UserSharingStatus(featureFlagsRepository: featureFlagsRepository,
                                passPlanRepository: passPlanRepository,
                                logManager: LogManagerMock())
    }

    func testUserSharingStatus_ShouldBeValid() async throws {
        featureFlagsRepository.stubbedGetFlagsResult = FeatureFlags(flags: [FeatureFlag(name: FeatureFlagType.passSharingV1.rawValue, enabled: true, variant: nil)])
        passPlanRepository.stubbedGetPlanResult = PassPlan(type: "plus",
                                                           internalName: "",
                                                           displayName: "",
                                                           hideUpgrade: true,
                                                           trialEnd: nil,
                                                           vaultLimit: nil,
                                                           aliasLimit: nil,
                                                           totpLimit: nil)
        let userStatus = await sut()
        XCTAssertTrue(userStatus)
    }
    
    func testUserSharingStatus_ShouldNotBeValid_BecauseOfFreeStatus() async throws {
        featureFlagsRepository.stubbedGetFlagsResult = FeatureFlags(flags: [FeatureFlag(name: FeatureFlagType.passSharingV1.rawValue, enabled: true, variant: nil)])
        passPlanRepository.stubbedGetPlanResult = PassPlan(type: "free",
                                                           internalName: "",
                                                           displayName: "",
                                                           hideUpgrade: true,
                                                           trialEnd: nil,
                                                           vaultLimit: nil,
                                                           aliasLimit: nil,
                                                           totpLimit: nil)
        let userStatus = await sut()
        XCTAssertFalse(userStatus)
    }
    
    func testUserSharingStatus_ShouldNotBeValid_BecauseOfFeatureFlag() async throws {
        featureFlagsRepository.stubbedGetFlagsResult = FeatureFlags(flags: [])
        passPlanRepository.stubbedGetPlanResult = PassPlan(type: "plus",
                                                           internalName: "",
                                                           displayName: "",
                                                           hideUpgrade: true,
                                                           trialEnd: nil,
                                                           vaultLimit: nil,
                                                           aliasLimit: nil,
                                                           totpLimit: nil)
        let userStatus = await sut()
        XCTAssertFalse(userStatus)
    }
}
