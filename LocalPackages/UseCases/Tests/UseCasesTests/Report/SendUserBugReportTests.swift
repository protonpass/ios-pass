//
// SendUserBugReportTests.swift
// Proton Pass - Created on 01/12/2025.
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

@testable import UseCases
import ClientMocks
import CoreMocks
import UseCasesMocks
import XCTest

// import Proton_Pass

final class SendUserBugReportTests: XCTestCase {
    var sut: SendUserBugReportUseCase!
    var repositoryMock: ReportRepositoryProtocolMock!
    var extractToFileMock: ExtractLogsToFileUseCaseMock!
    var getLogsMock: GetLogEntriesUseCaseMock!

    override func setUp() {
        super.setUp()
        repositoryMock = ReportRepositoryProtocolMock()
        extractToFileMock = ExtractLogsToFileUseCaseMock()
        getLogsMock = GetLogEntriesUseCaseMock()
        sut = SendUserBugReport(reportRepository: repositoryMock,
                                createLogsFile: CreateLogsFile(extractLogsToFile: extractToFileMock,
                                                               getLogEntries: getLogsMock))
    }

    func testSendBugReport() async throws {
        repositoryMock.stubbedSendBugResult = true
        getLogsMock.stubbedExecuteResult = [LogEntryFactory.createMock()]
        extractToFileMock.stubbedExecuteResult = URL(string: "ThisIsFake")
        let response = try await sut(with: "Test bug", and: "Bug description",
                                     shouldSendLogs: true)
        XCTAssertTrue(response)
        let params = try XCTUnwrap(repositoryMock.invokedSendBugParameters)
        XCTAssertEqual(params.0, "Test bug")
        XCTAssertEqual(params.1, "Bug description")
        XCTAssertEqual(params.2,
                       try [
                           "File0": XCTUnwrap(extractToFileMock.stubbedExecuteResult),
                           "File1": XCTUnwrap(extractToFileMock.stubbedExecuteResult)
                       ])
    }
}
