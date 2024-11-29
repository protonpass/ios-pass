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
                                                      flags: 2,
                                                      lastBreachTime: 1),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 10,
                                                      flags: 2,
                                                      lastBreachTime: 2),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 40,
                                                      flags: 2,
                                                      lastBreachTime: 5),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 20,
                                                      flags: 2,
                                                      lastBreachTime: 3),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 30,
                                                      flags: 2,
                                                      lastBreachTime: 4),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 50,
                                                      flags: 2,
                                                      lastBreachTime: 6),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 60,
                                                      flags: 2,
                                                      lastBreachTime: 7),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 70,
                                                      flags: 2,
                                                      lastBreachTime: 8),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 90,
                                                      flags: 2,
                                                      lastBreachTime: 10),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 100,
                                                      flags: 1,
                                                      lastBreachTime: 11),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 15,
                                                      flags: 2,
                                                      lastBreachTime: 11),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 80,
                                                      flags: 2,
                                                      lastBreachTime: 9),
                                        ProtonAddress(addressID: "testid",
                                                      email: "verified@proton.me",
                                                      breachCounter: 0,
                                                      flags: 2,
                                                      lastBreachTime: nil)
                                      ],
                                      customEmails: [],
                                      hasCustomDomains: false)
}

extension BreachEntitiesExtensionsTests {
    func testTopMostBreachedProtonAddresses() throws {
        let comparableArray = [
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 90,
                          flags: 2,
                          lastBreachTime: 10),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 80,
                          flags: 2,
                          lastBreachTime: 9),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 70,
                          flags: 2,
                          lastBreachTime: 8),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 60,
                          flags: 2,
                          lastBreachTime: 7),
            ProtonAddress(addressID: "testid",
                          email: "verified@proton.me",
                          breachCounter: 50,
                          flags: 2,
                          lastBreachTime: 6)
//            ,
//            ProtonAddress(addressID: "testid",
//                          email: "verified@proton.me",
//                          breachCounter: 40,
//                          flags: 2,
//                          lastBreachTime: 5),
//            ProtonAddress(addressID: "testid",
//                          email: "verified@proton.me",
//                          breachCounter: 30,
//                          flags: 2,
//                          lastBreachTime: 4),
//            ProtonAddress(addressID: "testid",
//                          email: "verified@proton.me",
//                          breachCounter: 20,
//                          flags: 2,
//                          lastBreachTime: 3),
//            ProtonAddress(addressID: "testid",
//                          email: "verified@proton.me",
//                          breachCounter: 15,
//                          flags: 2,
//                          lastBreachTime: 11),
//            ProtonAddress(addressID: "testid",
//                          email: "verified@proton.me",
//                          breachCounter: 10,
//                          flags: 2,
//                          lastBreachTime: 2)
        ]
        XCTAssertEqual(userBreachData.topBreachedAddresses.count, 5)
        XCTAssertEqual(userBreachData.topBreachedAddresses.first?.breachCounter, 90)
        XCTAssertEqual(userBreachData.topBreachedAddresses.last?.breachCounter, 50)
        XCTAssertEqual(userBreachData.topBreachedAddresses, comparableArray)
    }
}
