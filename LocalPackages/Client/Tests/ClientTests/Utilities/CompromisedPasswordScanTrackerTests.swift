//
// CompromisedPasswordScanTrackerTests.swift
// Proton Pass - Created on 30/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import ClientMocks
import Core
import Foundation
import Testing

private struct StubDateProvider: CurrentDateProviderProtocol {
    let date: Date
    func getCurrentDate() -> Date { date }
}

@Suite(.tags(.repository))
struct CompromisedPasswordScanTrackerTests {
    private let now = 1_000_000
    private let interval = Constants.CompromisedPasswords.minimumCheckInterval

    private func makeSUT(datasource: MockLocalTimestampDatasource = .init()) -> CompromisedPasswordScanTracker {
        let dateProvider = StubDateProvider(date: Date(timeIntervalSince1970: TimeInterval(now)))
        return CompromisedPasswordScanTracker(localTimestampDatasource: datasource, dateProvider: dateProvider)
    }

    @Test
    func `A full scan is due when none was recorded`() {
        #expect(makeSUT().isFullScanDue(userId: "user"))
    }

    @Test
    func `A full scan is not due inside the window`() {
        let datasource = MockLocalTimestampDatasource()
        datasource.setTimestamp(now - interval + 1, key: Constants.CompromisedPasswords.lastRunKey("user"))

        #expect(!makeSUT(datasource: datasource).isFullScanDue(userId: "user"))
    }

    @Test
    func `A full scan is due once the window elapses`() {
        let datasource = MockLocalTimestampDatasource()
        datasource.setTimestamp(now - interval, key: Constants.CompromisedPasswords.lastRunKey("user"))

        #expect(makeSUT(datasource: datasource).isFullScanDue(userId: "user"))
    }

    @Test
    func `A full scan is due when the clock moved backwards`() {
        let datasource = MockLocalTimestampDatasource()
        datasource.setTimestamp(now + 1, key: Constants.CompromisedPasswords.lastRunKey("user"))

        #expect(makeSUT(datasource: datasource).isFullScanDue(userId: "user"))
    }

    @Test
    func `Recording a full scan closes the window for that user only`() {
        let sut = makeSUT()

        sut.recordFullScan(userId: "user")

        #expect(!sut.isFullScanDue(userId: "user"))
        #expect(sut.isFullScanDue(userId: "other"))
    }

    @Test
    func `The corpus is considered changed when no change was recorded`() {
        #expect(!makeSUT().isCorpusUnchanged(userId: "user", currentLastChange: 1))
    }

    @Test
    func `The corpus is unchanged until a newer last change is seen`() {
        let sut = makeSUT()

        sut.recordCorpusLastChange(1_000, userId: "user")

        #expect(sut.isCorpusUnchanged(userId: "user", currentLastChange: 999))
        #expect(sut.isCorpusUnchanged(userId: "user", currentLastChange: 1_000))
        #expect(!sut.isCorpusUnchanged(userId: "user", currentLastChange: 1_001))
    }

    @Test
    func `Recording a full scan persists the current time under the last run key`() {
        let datasource = MockLocalTimestampDatasource()

        makeSUT(datasource: datasource).recordFullScan(userId: "user")

        #expect(datasource.getTimestamp(key: Constants.CompromisedPasswords.lastRunKey("user")) == now)
    }

    @Test
    func `Recording a corpus last change persists the value under the corpus key`() {
        let datasource = MockLocalTimestampDatasource()

        makeSUT(datasource: datasource).recordCorpusLastChange(1_000, userId: "user")

        #expect(datasource.getTimestamp(key: Constants.CompromisedPasswords.lastCorpusChangeKey("user")) == 1_000)
    }

    @Test
    func `Recording a corpus last change overwrites a newer stored value`() {
        let sut = makeSUT()

        sut.recordCorpusLastChange(1_000, userId: "user")
        sut.recordCorpusLastChange(500, userId: "user")

        #expect(!sut.isCorpusUnchanged(userId: "user", currentLastChange: 501))
    }

    @Test
    func `Recording a corpus last change affects that user only`() {
        let sut = makeSUT()

        sut.recordCorpusLastChange(1_000, userId: "user")

        #expect(sut.isCorpusUnchanged(userId: "user", currentLastChange: 1_000))
        #expect(!sut.isCorpusUnchanged(userId: "other", currentLastChange: 1_000))
    }

    @Test
    func `The full scan and corpus markers do not alias each other`() {
        let sut = makeSUT()

        sut.recordFullScan(userId: "user")
        #expect(!sut.isCorpusUnchanged(userId: "user", currentLastChange: 0))

        sut.recordCorpusLastChange(now, userId: "other")
        #expect(sut.isFullScanDue(userId: "other"))
    }
}
