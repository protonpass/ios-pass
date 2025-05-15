//
// GetUserEventsResponseTests.swift
// Proton Pass - Created on 15/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Testing

@Suite(.tags(.endpoint))
struct GetUserEventsResponseTests {
    @Test("Decode")
    func decode() throws {
        let given = """
            {
              "Code": 1000,
              "Events": {
                "LastEventID": "TestLastID",
                "ItemsUpdated": [
                  {
                    "ShareID": "ShareID1",
                    "ItemID": "ItemID1",
                    "EventToken": "Token1"
                  },
                  {
                    "ShareID": "ShareID2",
                    "ItemID": "ItemID2",
                    "EventToken": "Token2"
                  }
                ],
                "ItemsDeleted": [
                  {
                    "ShareID": "ShareID3",
                    "ItemID": "ItemID3",
                    "EventToken": "Token3"
                  }
                ],
                "SharesUpdated": [
                  {
                    "ShareID": "ShareID4",
                    "EventToken": "Token4"
                  },
                  {
                    "ShareID": "ShareID5",
                    "EventToken": "Token5"
                  }
                ],
                "SharesDeleted": [
                  {
                    "ShareID": "ShareID6",
                    "EventToken": "Token6"
                  }
                ],
                "SharesToGetInvites": [
                  {
                    "ShareID": "ShareID7",
                    "EventToken": "Token7"
                  }
                ],
                "SharesWithInvitesToCreate": [
                  {
                    "ShareID": "ShareID8",
                    "EventToken": "Token8"
                  }
                ],
                "PlanChanged": true,
                "EventsPending": true,
                "FullRefresh": false
              }
            }
            """

        let response = try GetUserEventsResponse.decode(from: given)
        let events = response.events
        #expect(events.lastEventID == "TestLastID")
        #expect(events.itemsUpdated.count == 2)
        #expect(events.itemsUpdated.first == UserEventItem(shareID: "ShareID1",
                                                           itemID: "ItemID1",
                                                           eventToken: "Token1"))
        #expect(events.itemsUpdated.last == UserEventItem(shareID: "ShareID2",
                                                          itemID: "ItemID2",
                                                          eventToken: "Token2"))
        #expect(events.itemsDeleted.count == 1)
        #expect(events.itemsDeleted.last == UserEventItem(shareID: "ShareID3",
                                                          itemID: "ItemID3",
                                                          eventToken: "Token3"))
        #expect(events.sharesUpdated.count == 2)
        #expect(events.sharesUpdated.first == UserEventShare(shareID: "ShareID4",
                                                             eventToken: "Token4"))
        #expect(events.sharesUpdated.last == UserEventShare(shareID: "ShareID5",
                                                            eventToken: "Token5"))
        #expect(events.sharesDeleted.count == 1)
        #expect(events.sharesDeleted.first == UserEventShare(shareID: "ShareID6",
                                                             eventToken: "Token6"))
        #expect(events.sharesToGetInvites.count == 1)
        #expect(events.sharesToGetInvites.first == UserEventShare(shareID: "ShareID7",
                                                                  eventToken: "Token7"))
        #expect(events.sharesWithInvitesToCreate.count == 1)
        #expect(events.sharesWithInvitesToCreate.first == UserEventShare(shareID: "ShareID8",
                                                                         eventToken: "Token8"))
        #expect(events.planChanged)
        #expect(events.eventsPending)
        #expect(!events.fullRefresh)
    }
}
