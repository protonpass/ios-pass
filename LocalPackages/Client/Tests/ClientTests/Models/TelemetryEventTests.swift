//
// TelemetryEventTests.swift
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
import XCTest

final class TelemetryEventTests: XCTestCase {
    func testEventTypeConversions() throws {
        let test: (TelemetryEventType, String) throws -> Void = { event, expectedOutput in
            XCTAssertEqual(event.rawValue, expectedOutput)

            let outputEvent = try XCTUnwrap(TelemetryEventType(rawValue: expectedOutput))
            XCTAssertEqual(event, outputEvent)
        }
        try test(.create(.login), "create.0")
        try test(.create(.alias), "create.1")
        try test(.create(.note), "create.2")
        try test(.read(.login), "read.0")
        try test(.read(.alias), "read.1")
        try test(.read(.note), "read.2")
        try test(.update(.login), "update.0")
        try test(.update(.alias), "update.1")
        try test(.update(.note), "update.2")
        try test(.delete(.login), "delete.0")
        try test(.delete(.alias), "delete.1")
        try test(.delete(.note), "delete.2")
        try test(.autofillDisplay, "autofill.display")
        try test(.autofillTriggeredFromSource, "autofill.triggered.source")
        try test(.autofillTriggeredFromApp, "autofill.triggered.app")
        try test(.searchTriggered, "search.triggered")
        try test(.searchClick, "search.click")
    }
}
