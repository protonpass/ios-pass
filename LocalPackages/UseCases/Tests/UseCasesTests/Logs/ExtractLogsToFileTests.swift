//
// ExtractLogsToFileTests.swift
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

import CoreMocks
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
final class ExtractLogsToFileTests {
    private let sut: any ExtractLogsToFileUseCase = ExtractLogsToFile(logFormatter: LogFormatterProtocolMock())
    private let fileName = "ExtractLogsToFileTests-\(UUID().uuidString).log"

    deinit {
        try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName))
    }

    @Test func `log entries are written to the named file in the temporary directory`() async throws {
        let url = try #require(try await sut(for: [LogEntryFactory.createMock()], in: fileName))

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.lastPathComponent == fileName)
        #expect(url.pathExtension == "log")
    }
}
