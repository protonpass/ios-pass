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
import Foundation
import Testing

@Suite(.tags(.manager))
struct BackOffManagerTests {
    private let currentDateProviderMock = CurrentDateProviderMock()
    private let sut: BackOffManager

    init() {
        sut = BackOffManager(currentDateProvider: currentDateProviderMock)
    }
}

extension BackOffManagerTests {
    @Test(arguments: zip([-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                         [BackOffStride.zeroSecond, .zeroSecond, .zeroSecond,
                          .oneSecond, .twoSeconds, .fiveSeconds, .tenSeconds, .thirtySeconds,
                          .oneMinute, .twoMinutes, .fiveMinutes, .tenMinutes,
                          .thirtyMinutes, .thirtyMinutes, .thirtyMinutes]))
    func `stride grows with the failure count and caps at thirty minutes`(failureCount: Int,
                                                                          expected: BackOffStride) {
        #expect(BackOffStride.stride(failureCount: failureCount) == expected)
    }

    @Test func `recording failures updates the count and last failure date`() async {
        var failures = await sut.lastFailureDate
        #expect(failures == nil)

        // When
        let date0 = Date.now

        // Then
        currentDateProviderMock.currentDateStub.bodyIs { _ in date0 }
        await sut.recordFailure()
        failures = await sut.lastFailureDate
        var count = await sut.failureCount
        #expect(count == 1)
        #expect(failures == date0)

        // When
        let date1 = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in date1 }
        await sut.recordFailure()

        // Then
        failures = await sut.lastFailureDate
        count = await sut.failureCount
        #expect(count == 2)
        #expect(failures == date1)

        // When
        let date2 = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in date2 }
        await sut.recordFailure()

        // Then
        failures = await sut.lastFailureDate
        count = await sut.failureCount

        #expect(count == 3)
        #expect(failures == date2)
    }

    @Test func `no failures means no need to back off`() async {
        let canProceed = await sut.canProceed()
        let failures = await sut.lastFailureDate

        #expect(canProceed)
        #expect(failures == nil)
    }

    @Test func `one failure backs off for one second`() async {
        // Given
        let failureDate = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate }

        // When
        await sut.recordFailure()

        // Then
        var canProceed = await sut.canProceed()
        var failures = await sut.lastFailureDate
        var count = await sut.failureCount
        #expect(!canProceed)
        #expect(count == 1)

        // When
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate.adding(component: .second,
                                                                                 value: 1) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount

        #expect(canProceed)
        #expect(count == 1)

        // When
        await sut.recordSuccess()

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        #expect(canProceed)
        #expect(failures == nil)
    }

    @Test func `two failures back off for two seconds`() async {
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
        var failures = await sut.lastFailureDate
        var count = await sut.failureCount

        #expect(!canProceed)
        #expect(count == 2)

        // When
        // Retry 2 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate1.adding(component: .second,
                                                                                  value: 2) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount

        #expect(canProceed)
        #expect(count == 2)

        // When
        await sut.recordSuccess()

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        #expect(canProceed)
        #expect(failures == nil)
    }

    @Test func `three failures back off for five seconds`() async {
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
        var failures = await sut.lastFailureDate
        var count = await sut.failureCount

        #expect(!canProceed)
        #expect(count == 3)

        // When
        // Retry 2 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 2) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount

        #expect(!canProceed)
        #expect(count == 3)

        // When
        // Retry 3 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 3) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount

        #expect(!canProceed)
        #expect(count == 3)

        // When
        // Retry 4 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 4) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount

        #expect(!canProceed)
        #expect(count == 3)

        // When
        // Retry 5 secs later
        currentDateProviderMock.currentDateStub.bodyIs { _ in failureDate2.adding(component: .second,
                                                                                  value: 5) }

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount
        #expect(canProceed)
        #expect(count == 3)

        // When
        await sut.recordSuccess()

        // Then
        canProceed = await sut.canProceed()
        failures = await sut.lastFailureDate
        count = await sut.failureCount
        #expect(canProceed)
        #expect(failures == nil)
    }
}

private extension Date {
    func radomNextFailureDate() -> Date {
        adding(component: .second, value: .random(in: 10...100))
    }
}
