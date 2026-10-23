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

import ClientMocks
import CoreMocks
import Foundation
import Testing
import UseCases
import UseCasesMocks

@Suite(.tags(.useCase))
struct SendUserBugReportTests {
    private let sut: any SendUserBugReportUseCase
    private let repositoryMock = ReportRepositoryProtocolMock()
    private let extractToFileMock = ExtractLogsToFileUseCaseMock()
    private let getLogsMock = GetLogEntriesUseCaseMock()

    init() {
        sut = SendUserBugReport(reportRepository: repositoryMock,
                                createLogsFile: CreateLogsFile(extractLogsToFile: extractToFileMock,
                                                               getLogEntries: getLogsMock))
    }

    @Test func `a bug report is sent with the host app and autofill log files`() async throws {
        repositoryMock.stubbedSendBugResult = true
        getLogsMock.stubbedExecuteResult = [LogEntryFactory.createMock()]
        extractToFileMock.stubbedExecuteResult = URL(string: "ThisIsFake")
        let response = try await sut(with: "Test bug", and: "Bug description", shouldSendLogs: true)
        #expect(response)
        let params = try #require(repositoryMock.invokedSendBugParameters)
        #expect(params.0 == "Test bug")
        #expect(params.1 == "Bug description")
        let logFile = try #require(extractToFileMock.stubbedExecuteResult)
        #expect(params.2 == ["File0": logFile, "File1": logFile])
    }
}
