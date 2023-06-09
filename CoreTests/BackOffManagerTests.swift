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
    private var sut: BackOffManagerProtocol!

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
    func testAddNewDatesToArrayWhenRecordingFailures() {
        XCTAssertTrue(sut.failureDates.isEmpty)

        // When
        let date0 = Date.now

        // Then
        currentDateProviderMock.currentDateStub.bodyIs { _ in date0 }
        sut.recordFailure()
        XCTAssertEqual(sut.failureDates.count, 1)
        XCTAssertEqual(sut.failureDates.first, date0)

        // When
        let date1 = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in date1 }
        sut.recordFailure()

        // Then
        XCTAssertEqual(sut.failureDates.count, 2)
        XCTAssertEqual(sut.failureDates.first, date0)
        XCTAssertEqual(sut.failureDates.last, date1)

        // When
        let date2 = Date.now
        currentDateProviderMock.currentDateStub.bodyIs { _ in date2 }
        sut.recordFailure()

        // Then
        XCTAssertEqual(sut.failureDates.count, 3)
        XCTAssertEqual(sut.failureDates[0], date0)
        XCTAssertEqual(sut.failureDates[1], date1)
        XCTAssertEqual(sut.failureDates[2], date2)
    }
}
