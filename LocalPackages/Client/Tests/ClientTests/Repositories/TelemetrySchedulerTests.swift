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

final class TelemetryThresholdProviderMock: TelemetryThresholdProviderProtocol {
    var telemetryThreshold: TimeInterval?

    func getThreshold() -> TimeInterval? {
        telemetryThreshold
    }

    func setThreshold(_ threshold: TimeInterval?) {
        telemetryThreshold = threshold
    }
}

final class TelemetrySchedulerTests: XCTestCase {
    var sut: TelemetrySchedulerProtocol!
    var thresholdProvider: TelemetryThresholdProviderMock!

    override func setUp() {
        super.setUp()
        thresholdProvider = TelemetryThresholdProviderMock()
        sut = TelemetryScheduler(currentDateProvider: MockedCurrentDateProvider(),
                                 thresholdProvider: thresholdProvider)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension TelemetrySchedulerTests {
    func testThresholdGetterAndSetter() {
        // When
        sut.threshhold = nil
        // Then
        XCTAssertNil(thresholdProvider.telemetryThreshold)

        // When
        let date = Date.now
        sut.threshhold = date
        // Then
        XCTAssertEqual(thresholdProvider.telemetryThreshold, date.timeIntervalSince1970)
    }

    func testShouldSendEventsWhenCurrentDateIsAfterThresholdDate() {
        // Given
        sut.threshhold = kMockedDate.adding(component: .minute, value: -1)

        // Then
        XCTAssertTrue(sut.shouldSendEvents())
    }

    func testShouldNotSendEventsWhenCurrentDateIsBeforeThresholdDate() {
        // Given
        sut.threshhold = kMockedDate.adding(component: .minute, value: 1)

        // Then
        XCTAssertFalse(sut.shouldSendEvents())
    }

    func testRandomNextThresholdDate() throws {
        // Given
        let givenThreshold = Date.now
        sut.threshhold = givenThreshold

        // When
        sut.randomNextThreshold()
        let newThreshhold = try XCTUnwrap(sut.threshhold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenThreshold,
                                                         to: newThreshhold)

        // Then
        let differenceInHours = try XCTUnwrap(difference.hour)
        XCTAssertTrue(differenceInHours >= sut.minIntervalInHours)
        XCTAssertTrue(differenceInHours <= sut.maxIntervalInHours)
    }
}
