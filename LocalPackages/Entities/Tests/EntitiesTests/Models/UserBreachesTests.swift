//  
// UserBreachesTests.swift
// Proton Pass - Created on 17/04/2024.
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
import XCTest

final class UserBreachesTests: XCTestCase {
    func testUserBreaches() {
        let latestbreach = BreachedDomain(domain: "test3", breachTime: 3)
        
        let userBreaches = UserBreaches(emailsCount: 3,
                                        domainsPeek: [BreachedDomain(domain: "test1", breachTime: 1),
                                                      BreachedDomain(domain: "test2", breachTime: 2),
                                                      latestbreach
                                                      ],
                                        addresses: [],
                                        customEmails: [CustomEmail(customEmailID: "test1",
                                                                   email: "test",
                                                                   verified: true,
                                                                   breachCounter: 1, 
                                                                   flags: 0,
                                                                   lastBreachTime: nil),
                                                       CustomEmail(customEmailID: "test2",
                                                                   email: "test",
                                                                   verified: true,
                                                                   breachCounter: 2, 
                                                                   flags: 0,
                                                                   lastBreachTime: nil),
                                                       CustomEmail(customEmailID: "test3",
                                                                   email: "test",
                                                                   verified: false,
                                                                   breachCounter: 3, 
                                                                   flags: 0, 
                                                                   lastBreachTime: nil)], hasCustomDomains: false)

        XCTAssertEqual(userBreaches.latestBreach, latestbreach)
        XCTAssertEqual(userBreaches.verifiedCustomEmails.count, 2)
        XCTAssertEqual(userBreaches.unverifiedCustomEmails.count, 1)
    }
}

