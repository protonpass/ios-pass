//
// BackOffManagerTests.swift
// Proton Pass - Created on 09/06/2023.
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

@testable import Core
import XCTest

final class BackOffManagerTests: XCTestCase {
    private var currentDateProviderMock: CurrentDateProviderMock!
    private var sut: BackOffManager!

    override func setUp() {
        super.setUp()
        currentDateProviderMock = CurrentDateProviderMock()
        sut = BackOffManager(currentDateProvider: currentDateProviderMock)
    }

    override func tearDown() {
        currentDateProviderMock = nil
        sut = nil
        super.tearDown()
    }
}

extension BackOffManagerTests {
    func testGetBackOffStrideFromFailureCount() {
        XCTAssertEqual(BackOffStride.stride(failureCount: -2), .zeroSecond)
        XCTAssertEqual(BackOffStride.stride(failureCount: -1), .zeroSecond)
        XCTAssertEqual(BackOffStride.stride(failureCount: 0), .zeroSecond)
        XCTAssertEqual(BackOffStride.stride(failureCount: 1), .oneSecond)
        XCTAssertEqual(BackOffStride.stride(failureCount: 2), .twoSeconds)
        XCTAssertEqual(BackOffStride.stride(failureCount: 3), .fiveSeconds)
        XCTAssertEqual(BackOffStride.stride(failureCount: 4), .tenSeconds)
        XCTAssertEqual(BackOffStride.stride(failureCount: 5), .thirtySeconds)
        XCTAssertEqual(BackOffStride.stride(failureCount: 6), .oneMinute)
        XCTAssertEqual(BackOffStride.stride(failureCount: 7), .twoMinutes)
        XCTAssertEqual(BackOffStride.stride(failureCount: 8), .fiveMinutes)
        XCTAssertEqual(BackOffStride.stride(failureCount: 9), .tenMinutes)
        XCTAssertEqual(BackOffStride.stride(failureCount: 10), .thirtyMinutes)
        XCTAssertEqual(BackOffStride.stride(failureCount: 11), .thirtyMinutes)
        XCTAssertEqual(BackOffStride.stride(failureCount: 12), .thirtyMinutes)
    }

    func testAddNewDatesToArrayWhenRecordingFailures() async {
        var failures = await sut.failureDates
        XCTAssertTrue(failures.isEmpty)

        // When
        let date0 = Date.now

        // Then
        currentDateProviderMock.currentDateStub.bodyIs { _ in date0 }
        await sut.recordFailure()
        failures = await sut.failureDates
        XCTAssertEqual(failures.count, 1)
        XCTAssertEqual(failures.first, date0)

        // When
        let date1 = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in date1 }
        await sut.recordFailure()

        // Then
        failures = await sut.failureDates
        XCTAssertEqual(failures.count, 2)
        XCTAssertEqual(failures.first, date0)
        XCTAssertEqual(failures.last, date1)

        // When
        let date2 = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in date2 }
        await sut.recordFailure()

        // Then
        failures = await sut.failureDates

        XCTAssertEqual(failures.count, 3)
        XCTAssertEqual(failures[0], date0)
        XCTAssertEqual(failures[1], date1)
        XCTAssertEqual(failures[2], date2)
    }

    func testNoFailuresNoNeedToBackOff() async {
        let canProceed = await sut.canProceed()
        let failures = await sut.failureDates

        XCTAssertTrue(canProceed)
        XCTAssertTrue(failures.isEmpty)
    }

    func testOneFailureBackOffOneSecond() async {
        // Given
        let failureDate = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate }

        // When
        await sut.recordFailure()

        // Then
        var canProceed = await sut.canProceed()
        var failures = await sut.failureDates

        XCTAssertFalse(canProceed)
        XCTAssertEqual(failures.count, 1)

        // When
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate.adding(component: .second,
                                                                                 value: 1) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertTrue(canProceed)
        XCTAssertEqual(failures.count, 1)

        // When
        await sut.recordSuccess()

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertTrue(canProceed)
        XCTAssertTrue(failures.isEmpty)
    }

    func testTwoFailuresBackOffTwoSeconds() async {
        // Given
        let failureDate0 = Date.now
        let failureDate1 = failureDate0.radomNextFailureDate()

        // When
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate0 }
        await sut.recordFailure()

        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate1 }
        await sut.recordFailure()

        // Retry 1 sec later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate1.adding(component: .second,
                                                                                  value: 1) }
        // Then
        var canProceed = await sut.canProceed()
        var failures = await sut.failureDates
        XCTAssertFalse(canProceed)
        XCTAssertEqual(failures.count, 2)

        // When
        // Retry 2 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate1.adding(component: .second,
                                                                                  value: 2) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertTrue(canProceed)
        XCTAssertEqual(failures.count, 2)

        // When
        await sut.recordSuccess()

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertTrue(canProceed)
        XCTAssertTrue(failures.isEmpty)
    }

    func testThreeFailuresBackOffFiveSeconds() async {
        // Given
        let failureDate0 = Date.now
        let failureDate1 = failureDate0.radomNextFailureDate()
        let failureDate2 = failureDate1.radomNextFailureDate()

        // When
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate0 }
        await sut.recordFailure()

        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate1 }
        await sut.recordFailure()

        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2 }
        await sut.recordFailure()

        // Retry 1 sec later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 1) }
        // Then
        var canProceed = await sut.canProceed()
        var failures = await sut.failureDates
        XCTAssertFalse(canProceed)
        XCTAssertEqual(failures.count, 3)

        // When
        // Retry 2 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 2) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertFalse(canProceed)
        XCTAssertEqual(failures.count, 3)

        // When
        // Retry 3 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 3) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertFalse(canProceed)
        XCTAssertEqual(failures.count, 3)

        // When
        // Retry 4 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 4) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertFalse(canProceed)
        XCTAssertEqual(failures.count, 3)

        // When
        // Retry 5 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 5) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertTrue(canProceed)
        XCTAssertEqual(failures.count, 3)

        // When
        await sut.recordSuccess()

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.failureDates
        XCTAssertTrue(canProceed)
        XCTAssertTrue(failures.isEmpty)
    }
}

private extension Date {
    func radomNextFailureDate() -> Date {
        adding(component: .second, value: .random(in: 10...100))
    }
}
