//
// DimensionsTests.swift
// Proton Pass - Created on 19/04/2023.
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
import Entities
import Testing
import Foundation

@Suite(.tags(.models))
struct DimensionsTests {
    @Test("Test generic telemetry dimension encoding conversion")
    func testDimensionConversions() throws {
        let dimensions = Dimensions(properties: [
            "userId": "A string value",
            "notificationKey": "notification_Key",
            "doubleValue": 3.14,
            "boolValue": true
        ])
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let decodeData = try encoder.encode(dimensions)
        
        // Convert JSON data to a string for easy comparison and output
        let jsonString = try #require(String(data: decodeData, encoding: .utf8))
        
        #expect(jsonString.contains("userId"))
        #expect(jsonString.contains("notificationKey"))
        #expect(jsonString.contains("doubleValue"))
        #expect(jsonString.contains("boolValue"))
    }
    
    @Test("Test event info telemetry with generic dimension encoding conversion")
    func testEvenInfoConversions() throws {
        let telemetrie = TelemetryEvent(uuid: "idTest",
                                        time: 0,
                                        type: .notificationChangeStatus(key: "notificationKey",
                                                                        status: 3))
        let event = EventInfo(event: telemetrie, userTier: "user tier")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let decodeData = try encoder.encode(event)
        
        // Convert JSON data to a string for easy comparison and output
        let jsonString = try #require(String(data: decodeData, encoding: .utf8))
        
        #expect(jsonString.contains("user_tier"))
        #expect(jsonString.contains("notificationKey"))
        #expect(jsonString.contains("notificationStatus"))
    }
}
