//
// InternalNavigationDestinationTests.swift
// Proton Pass - Created on 19/11/2024.
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

struct InternalNavigationDestinationTestCase: Sendable {
   let name: String
    let input:String
    let expectation: InternalNavigationDestination?
}

@Suite(.tags(.entity))
struct InternalNavigationDestinationTests {
    @Test("In app navigation destination parsing",
          arguments: [
            InternalNavigationDestinationTestCase(
                name: "ViewVaultMembers with ShareID",
                input: "/internal/share_members?ShareID=a1b2c3d4==",
                expectation: .viewVaultMembers(shareID: "a1b2c3d4==")
            ),
            InternalNavigationDestinationTestCase(
                name: "AliasBreach with ShareID and ItemID",
                input: "/internal/alias_breach?ShareID=a1b2c3d4==&ItemID=e5f6g7h8==",
                expectation: .aliasBreach(shareID: "a1b2c3d4==", itemID: "e5f6g7h8==")
            ),
            InternalNavigationDestinationTestCase(
                name: "CustomEmailBreach with CustomEmailID",
                input: "/internal/custom_email_breach?CustomEmailID=c9d10e11==",
                expectation: .customEmailBreach(customEmailID: "c9d10e11==")
            ),
            InternalNavigationDestinationTestCase(
                name: "AddressBreach with AddressID",
                input: "/internal/address_breach?AddressID=a12b13c14==",
                expectation: .addressBreach(addressID: "a12b13c14==")
            ),
            InternalNavigationDestinationTestCase(
                name: "Upgrade with no parameters",
                input: "/internal/upgrade",
                expectation: .upgrade
            ),
            InternalNavigationDestinationTestCase(
                name: "ViewItem with ShareID and ItemID",
                input: "/internal/view_item?ShareID=a1b2c3d4==&ItemID=e5f6g7h8==",
                expectation: .viewItem(shareID: "a1b2c3d4==", itemID: "e5f6g7h8==")
            ),
            InternalNavigationDestinationTestCase(
                name: "Unknown route",
                input: "/internal/unknown_route",
                expectation: nil
            ),
            InternalNavigationDestinationTestCase(
                name: "Missing parameters",
                input: "/internal/share_members",
                expectation: nil
            ),
            InternalNavigationDestinationTestCase(
                name: "Extra parameters",
                input: "/internal/share_members?ShareID=a1b2c3d4==&ExtraParam=value",
                expectation: .viewVaultMembers(shareID: "a1b2c3d4==")
            )
            ])
    func encodingDecodingTelemetryEventType(testCase: InternalNavigationDestinationTestCase) {
        let expectation = InternalNavigationDestination.parse(urlString: testCase.input)
        #expect(expectation == testCase.expectation)
    }
}
