//
// TelemetrySchedulerTests.swift
// Proton Pass - Created on 25/04/2023.
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
import Core
import XCTest

private let kMockedDate = Date.now

private final class MockedCurrentDateProvider: CurrentDateProviderProtocol {
    func getCurrentDate() -> Date { kMockedDate }
}

final class TelemetryThresholdProviderMock: @unchecked Sendable, TelemetryThresholdProviderProtocol {
    var telemetryThreshold: TimeInterval?

    func getThreshold() -> TimeInterval? {
        telemetryThreshold
    }

    func setThreshold(_ threshold: TimeInterval?) async throws {
        telemetryThreshold = threshold
    }
}

final class TelemetrySchedulerTests: XCTestCase {
    var sut: TelemetryScheduler!
    var thresholdProvider: TelemetryThresholdProviderMock!

    override func setUp() {
        super.setUp()
        thresholdProvider = TelemetryThresholdProviderMock()
        sut = TelemetryScheduler(currentDateProvider: MockedCurrentDateProvider(),
                                 thresholdProvider: thresholdProvider)
    }

    override func tearDown() {
        sut = nil
        thresholdProvider = nil
        super.tearDown()
    }
}

extension TelemetrySchedulerTests {
    func testThresholdGetterAndSetter() {
        // When
        thresholdProvider.telemetryThreshold = nil
        // Then
        XCTAssertNil(thresholdProvider.telemetryThreshold)

        // When
        let date = Date.now
        thresholdProvider.telemetryThreshold = date.timeIntervalSince1970
        // Then
        XCTAssertEqual(thresholdProvider.telemetryThreshold, date.timeIntervalSince1970)
    }

    func testShouldSendEventsWhenCurrentDateIsAfterThresholdDate() async throws {
        // Given
        thresholdProvider.telemetryThreshold = kMockedDate.adding(component: .minute, value: -1).timeIntervalSince1970

        // Then
        let result = try await sut.shouldSendEvents()
        XCTAssertTrue(result)
    }

    func testShouldNotSendEventsWhenCurrentDateIsBeforeThresholdDate() async throws {
        // Given
        thresholdProvider.telemetryThreshold = kMockedDate.adding(component: .minute, value: 1).timeIntervalSince1970

        // Then
        let result = try await sut.shouldSendEvents()

        XCTAssertFalse(result)
    }

    func testRandomNextThresholdDate() async throws {
        // Given
        let givenThreshold = Date.now
        thresholdProvider.telemetryThreshold = givenThreshold.timeIntervalSince1970

        // When
        try await sut.randomNextThreshold()
        let threshhold = await sut.getThreshold()
        let newThreshhold = try XCTUnwrap(threshhold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenThreshold,
                                                         to: newThreshhold)

        // Then
        let differenceInHours = try XCTUnwrap(difference.hour)
        let min = await sut.minIntervalInHours
        let max = await sut.maxIntervalInHours
        XCTAssertTrue(differenceInHours >= min)
        XCTAssertTrue(differenceInHours <= max)
    }
}
