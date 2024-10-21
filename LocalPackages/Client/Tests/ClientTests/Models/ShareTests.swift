//
// ShareTests.swift
// Proton Pass - Created on 31/03/2023.
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

final class ShareTests: XCTestCase {
    func testClone() {
        // Given
        let givenShare = Share(shareID: .random(),
                               vaultID: .random(),
                               addressID: .random(),
                               targetType: .random(in: 100...200),
                               targetID: .random(),
                               permission: .random(in: 100...200),
                               shareRoleID: "1",
                               targetMembers: 2,
                               targetMaxMembers: 10, 
                               pendingInvites: 3,
                               newUserInvitesReady: 0,
                               owner: .random(),
                               shared: true,
                               content: .random(),
                               contentKeyRotation: .random(in: 100...200),
                               contentFormatVersion: .random(in: 100...200),
                               expireTime: .random(in: 100...200),
                               createTime: .random(in: 100...200),
                               canAutoFill: .random())

        // When
        let clonedShare = givenShare.copy(pendingInvites: 10)

        // Then
        XCTAssertEqual(givenShare.shareID, clonedShare.shareID)
        XCTAssertEqual(givenShare.vaultID, clonedShare.vaultID)
        XCTAssertEqual(givenShare.addressID, clonedShare.addressID)
        XCTAssertEqual(givenShare.targetType, clonedShare.targetType)
        XCTAssertEqual(givenShare.targetID, clonedShare.targetID)
        XCTAssertEqual(givenShare.permission, clonedShare.permission)
        XCTAssertEqual(givenShare.content, clonedShare.content)
        XCTAssertEqual(givenShare.contentKeyRotation, clonedShare.contentKeyRotation)
        XCTAssertEqual(givenShare.contentFormatVersion, clonedShare.contentFormatVersion)
        XCTAssertEqual(givenShare.expireTime, clonedShare.expireTime)
        XCTAssertEqual(givenShare.createTime, clonedShare.createTime)
        XCTAssertEqual(clonedShare.pendingInvites, 10)
    }
}
