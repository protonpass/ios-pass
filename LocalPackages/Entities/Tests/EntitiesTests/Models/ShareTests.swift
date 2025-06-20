//
// ShareTests.swift
// Proton Pass - Created on 28/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Foundation

@Suite(.tags(.entity))
struct ShareTests {
    let decoder = JSONDecoder()
    
    // MARK: - Sample JSON
    private let validVaultJSON = """
    {
        "shareID": "12345",
        "vaultID": "vault123",
        "addressID": "address789",
        "targetType": 1,
        "targetID": "target456",
        "permission": 2,
        "shareRoleID": "1",
        "targetMembers": 10,
        "targetMaxMembers": 15,
        "pendingInvites": 2,
        "newUserInvitesReady": 1,
        "owner": true,
        "shared": true,
        "content": "9+uF8qPa1M0ZIUZ6A6H2xILDvRtEQQ49pQUXbEst15miSqfja/14+g===",
        "contentKeyRotation": 3,
        "contentFormatVersion": 2,
        "expireTime": 1699872000,
        "createTime": 1699785600,
        "canAutoFill": true,
        "hidden": true
    }
    """.data(using: .utf8)!
    
    private let invalidJSON = """
        {
            "shareID": "12345",
            "vaultID": "vault123",
            "addressID": "address789",
            "targetType": "invalidType"
        }
        """.data(using: .utf8)!
    
    @Test("Share can be decoded")
    func decodingShare() throws {
        let share = try decoder.decode(Share.self, from: validVaultJSON)
        #expect(share.shareID ==  "12345")
        #expect(share.vaultID == "vault123")
        #expect(share.targetType == 1)
        #expect(share.targetID == "target456")
        #expect(share.owner)
        #expect(share.shared)
        #expect(share.members == 10)
        #expect(share.maxMembers == 15)
        #expect(share.pendingInvites == 2)
        #expect(share.contentKeyRotation == 3)
        #expect(share.contentFormatVersion == 2)
        #expect(share.expireTime == 1699872000)
        #expect(share.createTime == 1699785600)
        #expect(share.canAutoFill)
        #expect(share.hidden)
    }

    @Test("Share can't be decoded")
    func failDecodingShare() throws {
        #expect(throws: DecodingError.self) { try decoder.decode(Share.self, from: invalidJSON) }
    }
    
    
    @Test("Check computed properties")
    func computedProperties() throws {
        let share = try decoder.decode(Share.self, from: validVaultJSON)
        #expect(share.isManager)
        #expect(share.reachedSharingLimit == false)
        #expect(share.canShareWithMorePeople)
        #expect(share.totalOverallMembers == 12)
        #expect(share.isVaultRepresentation)

    }
    
    @Test("Decoding item share")
    func decodingWithNilContent() throws {
        let json = """
            {
                "shareID": "12345",
                "vaultID": "vault123",
                "addressID": "address789",
                "targetType": 2,
                "targetID": "target456",
                "permission": 2,
                "shareRoleID": "admin",
                "targetMembers": 10,
                "targetMaxMembers": 15,
                "pendingInvites": 2,
                "newUserInvitesReady": 1,
                "owner": true,
                "shared": true,
                "content": null,
                "contentKeyRotation": null,
                "contentFormatVersion": null,
                "expireTime": null,
                "createTime": 1699785600,
                "canAutoFill": true,
                "hidden": false
            }
            """.data(using: .utf8)!
        
        let share = try decoder.decode(Share.self, from: json)
        
        #expect(share.contentKeyRotation == nil)
        #expect(share.vaultContent == nil)
        #expect(share.contentFormatVersion == nil)
        #expect(!share.isVaultRepresentation)
        #expect(!share.hidden)
    }
    
    @Test("Share edge cases for members. Reached limit")
    func reachedLimiteForMembers() throws {
        let json = """
            {
                "shareID": "12345",
                "vaultID": "vault123",
                "addressID": "address789",
                "targetType": 1,
                "targetID": "target456",
                "permission": 2,
                "shareRoleID": "admin",
                "targetMembers": 15,
                "targetMaxMembers": 15,
                "pendingInvites": 0,
                "newUserInvitesReady": 1,
                "owner": true,
                "shared": true,
                "content": null,
                "contentKeyRotation": null,
                "contentFormatVersion": null,
                "expireTime": null,
                "createTime": 1699785600,
                "canAutoFill": true,
                "hidden": false
            }
            """.data(using: .utf8)!
        
        let share = try decoder.decode(Share.self, from: json)
        #expect(share.reachedSharingLimit)
        #expect(share.canShareWithMorePeople == false)
    }
}
