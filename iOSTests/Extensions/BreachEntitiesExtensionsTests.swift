//
// BreachEntitiesExtensionsTests.swift
// Proton Pass - Created on 22/04/2024.
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

import Entities
import Foundation
import XCTest
@testable import Proton_Pass

final class BreachEntitiesExtensionsTests: XCTestCase {
    var userBreachData = UserBreaches(emailsCount: 3,
                                      domainsPeek: [],
                                      addresses: [
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 1,
                                                      flags: 0,
                                                      lastBreachTime: 1),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 10,
                                                      flags: 0,
                                                      lastBreachTime: 2),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 40,
                                                      flags: 0,
                                                      lastBreachTime: 5),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 20,
                                                      flags: 0,
                                                      lastBreachTime: 3),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 30,
                                                      flags: 0,
                                                      lastBreachTime: 4),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 50,
                                                      flags: 0,
                                                      lastBreachTime: 6),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 60,
                                                      flags: 0,
                                                      lastBreachTime: 7),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 70,
                                                      flags: 0,
                                                      lastBreachTime: 8),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 90,
                                                      flags: 0,
                                                      lastBreachTime: 10),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 100,
                                                      flags: 1,
                                                      lastBreachTime: 11),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 15,
                                                      flags: 0,
                                                      lastBreachTime: 11),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 80,
                                                      flags: 0,
                                                      lastBreachTime: 9),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 0,
                                                      flags: 0,
                                                      lastBreachTime: nil)
                                      ],
                                      customEmails: [],
                                      hasCustomDomains: false)
    
//    let aliasMonitorInfoData = [AliasMonitorInfo(alias:
//                                                 breaches: EmailBreaches(isEligible: true,
//                                                                         count: 3,
//                                                                         breaches: [Breach(id: <#T##String#>,
//                                                                                           email: <#T##String#>,
//                                                                                           severity: <#T##Double#>,
//                                                                                           name: <#T##String#>,
//                                                                                           createdAt: <#T##String#>,
//                                                                                           publishedAt: <#T##String#>,
//                                                                                           source: <#T##BreachSource#>,
//                                                                                           size: <#T##Int?#>,
//                                                                                           exposedData: <#T##[BreachExposedData]#>,
//                                                                                           passwordLastChars: <#T##String#>,
//                                                                                           actions: <#T##[BreachAction]#>)],
//                                                                         samples: [])) ]
//    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
}

extension ItemContent {
    var monitoredAlias: ItemContent {
        ItemContent(shareId: "test",
                    itemUuid: "test",
                    item: Item(itemID: "test",
                               revision: 1,
                               contentFormatVersion: 1,
                               keyRotation: 1,
                               content: "",
                               itemKey: nil,
                               state: 1,
                               pinned: false,
                               aliasEmail: "test@test.com",
                               createTime: 1,
                               modifyTime: 1,
                               lastUseTime: 1,
                               revisionTime: 1,
                               flags: 0),
                    name: "plop",
                    note: "",
                    contentData: .alias,
                    customFields: [])
    }
    
    var unmonitoredAlias: ItemContent {
        ItemContent(shareId: "test",
                    itemUuid: "test",
                    item: Item(itemID: "test",
                               revision: 1,
                               contentFormatVersion: 1,
                               keyRotation: 1,
                               content: "",
                               itemKey: nil,
                               state: 1,
                               pinned: false,
                               aliasEmail: "test@test.com",
                               createTime: 1,
                               modifyTime: 1,
                               lastUseTime: 1,
                               revisionTime: 1,
                               flags: 1),
                    name: "plop",
                    note: "",
                    contentData: .alias,
                    customFields: [])
    }
}

extension BreachEntitiesExtensionsTests {
    func testTopMostBreachedProtonAddresses() throws {
        let comparableArray = [
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 90,
                          flags: 0,
                          lastBreachTime: 10),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 80,
                          flags: 0,
                          lastBreachTime: 9),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 70,
                          flags: 0,
                          lastBreachTime: 8),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 60,
                          flags: 0,
                          lastBreachTime: 7),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 50,
                          flags: 0,
                          lastBreachTime: 6),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 40,
                          flags: 0,
                          lastBreachTime: 5),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 30,
                          flags: 0,
                          lastBreachTime: 4),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 20,
                          flags: 0,
                          lastBreachTime: 3),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 15,
                          flags: 0,
                          lastBreachTime: 11),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 10,
                          flags: 0,
                          lastBreachTime: 2)
        ]
        XCTAssertEqual(userBreachData.topTenBreachedAddresses.count, 10)
        XCTAssertEqual(userBreachData.topTenBreachedAddresses.first?.breachCounter, 90)
        XCTAssertEqual(userBreachData.topTenBreachedAddresses.last?.breachCounter, 10)
        XCTAssertEqual(userBreachData.topTenBreachedAddresses, comparableArray)
    }
}