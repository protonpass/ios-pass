//
// Share+ShareProviderTests.swift
// Proton Pass - Created on 18/07/2022.
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
import ProtonCore_DataModel
import ProtonCore_Login
import XCTest

// swiftlint:disable function_body_length

final class SharePlusShareProviderTests: XCTestCase {
    func testGetVaultSuccess() throws {
        let givenVault = VaultProtobuf(name: .random(), description: .random())
        let testUser = UserData.test
        let request = try CreateVaultRequest(userData: testUser,
                                             name: givenVault.name,
                                             description: givenVault.description)

        let createdShare = Share(shareID: .random(),
                                 vaultID: .random(),
                                 addressID: (try? testUser.getAddressKey().addressId) ?? "",
                                 targetType: ShareType.vault.rawValue,
                                 targetID: .random(),
                                 permission: 0,
                                 content: request.content,
                                 contentKeyRotation: 0,
                                 contentFormatVersion: 1,
                                 expireTime: nil,
                                 createTime: 0)

        let shareKeys: [ShareKey] = [.init(key: .random(), keyRotation: 0, createTime: 0)]

        let shareContent = try createdShare.getShareContent(userData: testUser, shareKeys: shareKeys)
        switch shareContent {
        case .vault(let vault):
            XCTAssertEqual(givenVault.name, vault.name)
            XCTAssertEqual(givenVault.description, vault.description)
        case .item:
            XCTFail("Expect vault not item")
        }
    }
}
