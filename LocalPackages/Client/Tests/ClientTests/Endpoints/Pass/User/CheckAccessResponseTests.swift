//  
// CheckAccessResponseTests.swift
// Proton Pass - Created on 16/10/2023.
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
//

@testable import Client
import Entities
import XCTest

final class CheckAccessResponseTests: XCTestCase {
    func testDecode() throws {
        // Given
        let string = """
{
   "Code":1000,
   "Access":{
      "Plan":{
         "Type":"free",
         "InternalName":"bundle2022",
         "DisplayName":"Unlimited",
         "HideUpgrade":true,
        "ManageAlias": false,
         "TrialEnd":163823923,
         "VaultLimit":1,
         "AliasLimit":10,
         "TotpLimit":3,
         "StorageAllowed":false,
         "StorageUsed":1,
         "StorageQuota":2
      },
      "Monitor":{
         "ProtonAddress": true,
         "Aliases": false
      },
      "PendingInvites":3,
      "WaitingNewUserInvites":0,
      "UserData": {
            "DefaultShareID": null,
            "AliasSyncEnabled": false,
            "PendingAliasToSync": 0
       }
   }
}
"""
        let expectedResult =
        CheckAccessResponse(access: Access(plan: .init(type: "free",
                                                       internalName: "bundle2022",
                                                       displayName: "Unlimited",
                                                       hideUpgrade: true,
                                                       manageAlias: false,
                                                       trialEnd: 163823923,
                                                       vaultLimit: 1,
                                                       aliasLimit: 10,
                                                       totpLimit: 3,
                                                       storageAllowed: false,
                                                       storageUsed: 1,
                                                       storageQuota: 2),
                                           monitor: .init(protonAddress: true, aliases: false),
                                           pendingInvites: 3,
                                           waitingNewUserInvites: 0,
                                           minVersionUpgrade: nil,
                                           userData: UserAliasSyncData.default))

        // When
        let sut = try CheckAccessResponse.decode(from: string)

        // Then
        XCTAssertEqual(sut, expectedResult)
    }
}
