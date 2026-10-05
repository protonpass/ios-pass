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
import Foundation
import Testing

private let kMockedDate = Date.now

private final class MockedCurrentDateProvider: CurrentDateProviderProtocol {
    func getCurrentDate() -> Date { kMockedDate }
}

final class TelemetryThresholdProviderMock: @unchecked Sendable, TelemetryThresholdProviderProtocol {
    var telemetryThreshold: TimeInterval?

    func getThreshold() -> TimeInterval? {
        telemetryThreshold
    }

    func setThreshold(_ threshold: TimeInterval?) {
        telemetryThreshold = threshold
    }
}

@Suite(.tags(.repository))
struct TelemetrySchedulerTests {
    private let thresholdProvider = TelemetryThresholdProviderMock()
    private let sut: TelemetryScheduler

    init() {
        sut = TelemetryScheduler(currentDateProvider: MockedCurrentDateProvider(),
                                 thresholdProvider: thresholdProvider)
    }
}

extension TelemetrySchedulerTests {
    @Test func `events are sent once the threshold date has passed`() async throws {
        thresholdProvider.telemetryThreshold = kMockedDate.adding(component: .minute, value: -1).timeIntervalSince1970

        let result = try await sut.shouldSendEvents()
        #expect(result)
    }

    @Test func `events are not sent before the threshold date`() async throws {
        thresholdProvider.telemetryThreshold = kMockedDate.adding(component: .minute, value: 1).timeIntervalSince1970

        let result = try await sut.shouldSendEvents()
        #expect(!result)
    }

    @Test func `the next threshold is randomly picked within the allowed interval`() async throws {
        let givenThreshold = kMockedDate
        thresholdProvider.telemetryThreshold = givenThreshold.timeIntervalSince1970

        try await sut.randomNextThreshold()
        let newThreshold = try #require(await sut.getThreshold())
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenThreshold,
                                                         to: newThreshold)

        let differenceInHours = try #require(difference.hour)
        let min = await sut.minIntervalInHours
        let max = await sut.maxIntervalInHours
        #expect(differenceInHours >= min)
        #expect(differenceInHours <= max)
    }
}
