//
// LocalDatasourceTests+CDShare.swift
// Proton Pass - Created on 03/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

// swiftlint:disable function_body_length
extension LocalDatasourceTests {
    func testFetchShares() throws {
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShares = (1...Int.random(in: 1...100)).map { _ in Share.random() }
            let givenUserId = String.random()

            // When
            try await sut.insertShares(givenShares, withUserId: givenUserId)
            // Populate the database with arbitrary shares
            // this is to test if fetching shares by userId correctly work
            for _ in 0...10 {
                try await sut.insertShares([.random()], withUserId: .random())
            }

            // Then
            let shares = try await sut.fetchShares(forUserId: givenUserId)
            let shareIds = Set(shares.map { $0.shareID })
            let givenShareIds = Set(givenShares.map { $0.shareID })
            if shareIds == givenShareIds {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testUpdateShares() throws {
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenUserId = String.random()
            let insertedShare = try await givenInsertedShare(withUserId: givenUserId)
            // Only copy the shareId from givenShare
            let updatedShare = Share(shareID: insertedShare.shareID,
                                     vaultID: .random(),
                                     targetType: .random(in: 1...100),
                                     targetID: .random(),
                                     permission: .random(in: 1...100),
                                     acceptanceSignature: .random(),
                                     inviterEmail: .random(),
                                     inviterAcceptanceSignature: .random(),
                                     signingKey: .random(),
                                     signingKeyPassphrase: .random(),
                                     content: .random(),
                                     contentRotationID: .random(),
                                     contentEncryptedAddressSignature: .random(),
                                     contentEncryptedVaultSignature: .random(),
                                     contentSignatureEmail: .random(),
                                     contentFormatVersion: .random(in: 1...100),
                                     expireTime: .random(in: 1...100),
                                     createTime: .random(in: 1...100))

            // When
            try await sut.insertShares([updatedShare], withUserId: givenUserId)

            // Then
            continueAfterFailure = false
            let shares = try await sut.fetchShares(forUserId: givenUserId)
            XCTAssertEqual(shares.count, 1)
            let share = try XCTUnwrap(shares.first)
            XCTAssertEqual(share.shareID, updatedShare.shareID)
            XCTAssertEqual(share.vaultID, updatedShare.vaultID)
            XCTAssertEqual(share.targetType, updatedShare.targetType)
            XCTAssertEqual(share.targetID, updatedShare.targetID)
            XCTAssertEqual(share.permission, updatedShare.permission)
            XCTAssertEqual(share.acceptanceSignature, updatedShare.acceptanceSignature)
            XCTAssertEqual(share.inviterEmail, updatedShare.inviterEmail)
            XCTAssertEqual(share.inviterAcceptanceSignature,
                           updatedShare.inviterAcceptanceSignature)
            XCTAssertEqual(share.signingKey, updatedShare.signingKey)
            XCTAssertEqual(share.signingKeyPassphrase, updatedShare.signingKeyPassphrase)
            XCTAssertEqual(share.content, updatedShare.content)
            XCTAssertEqual(share.contentRotationID, updatedShare.contentRotationID)
            XCTAssertEqual(share.contentEncryptedAddressSignature,
                           updatedShare.contentEncryptedAddressSignature)
            XCTAssertEqual(share.contentEncryptedVaultSignature,
                           updatedShare.contentEncryptedVaultSignature)
            XCTAssertEqual(share.contentEncryptedAddressSignature,
                           updatedShare.contentEncryptedAddressSignature)
            XCTAssertEqual(share.contentFormatVersion,
                           updatedShare.contentFormatVersion)
            XCTAssertEqual(share.expireTime, updatedShare.expireTime)
            XCTAssertEqual(share.createTime, updatedShare.createTime)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
