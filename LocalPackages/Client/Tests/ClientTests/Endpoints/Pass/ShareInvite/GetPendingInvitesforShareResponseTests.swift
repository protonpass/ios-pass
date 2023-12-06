//  
// GetPendingInvitesforShareResponseTests.swift
// Proton Pass - Created on 17/10/2023.
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

final class GetPendingInvitesforShareResponseTests: XCTestCase {
    func testDecode() throws {
        // Given
        let string = """
{
   "Invites":[
      {
         "InviteID":"a1b2c3==",
         "InvitedEmail":"invited@user.tld",
         "InviterEmail":"inviter@user.tld",
         "ShareRoleID": "a2b2c3==",
         "TargetType":1,
         "TargetID":"a1b2c3==",
         "RemindersSent":1,
         "CreateTime":1674816424,
         "ModifyTime":1674816424
      }
   ],
   "NewUserInvites":[
      {
         "NewUserInviteID":"ASDOL983124lsdF==",
         "State":1,
         "TargetType":1,
         "TargetID":"a2b2c3==",
         "ShareRoleID":"a2b2c3==",
         "InvitedEmail":"invited@someemail.tld",
         "InviterEmail":"inviter@someemail.tld",
         "Signature":"Aada9o83rqaw==",
         "CreateTime":1674813070,
         "ModifyTime":1674813070
      }
   ],
   "Code":1000
}
"""
        let existingUserInvite = ShareExistingUserInvite(inviteID: "a1b2c3==",
                                                        invitedEmail: "invited@user.tld",
                                                        inviterEmail: "inviter@user.tld",
                                                        shareRoleID: "a2b2c3==",
                                                        targetType: 1,
                                                        targetID: "a1b2c3==",
                                                        remindersSent: 1,
                                                        createTime: 1674816424,
                                                        modifyTime: 1674816424)

        let newUserInvite = ShareNewUserInvite(newUserInviteID: "ASDOL983124lsdF==",
                                               state: 1,
                                               targetType: 1,
                                               targetID: "a2b2c3==",
                                               shareRoleID: "a2b2c3==",
                                               invitedEmail: "invited@someemail.tld",
                                               inviterEmail: "inviter@someemail.tld",
                                               signature: "Aada9o83rqaw==",
                                               createTime: 1674813070,
                                               modifyTime: 1674813070)

        let expectedResult = GetPendingInvitesForShareResponse(invites: [existingUserInvite],
                                                               newUserInvites: [newUserInvite])

        // When
        let sut = try GetPendingInvitesForShareResponse.decode(from: string)

        // Then
        XCTAssertEqual(sut, expectedResult)
    }
}

