//  
// InviteNewUserToShareRequestTests.swift
// Proton Pass - Created on 13/10/2023.
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
import Foundation
import Testing
import TestingToolkit

@Suite(.tags(.endpoint))
struct InviteNewUserToShareRequestTests {
    @Test func `new user invite request encodes every field`() throws {
        let now = Date.now
        let sut = InviteNewUserToShareRequest(email: "john.doe@example.com",
                                              targetType: .item,
                                              signature: "signature_test",
                                              shareRole: .read,
                                              itemId: "item_id_test",
                                              expirationDate: now)
        #expect(try sortedPrettyJSON(sut) == """
        {
          "Email" : "john.doe@example.com",
          "ExpirationTime" : \(Int(now.timeIntervalSince1970)),
          "ItemID" : "item_id_test",
          "ShareRoleID" : "3",
          "Signature" : "signature_test",
          "TargetType" : 2
        }
        """)
    }
}
