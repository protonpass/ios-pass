//
//
// SendUserFeedBack.swift
// Proton Pass - Created on 29/06/2023.
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
//
import Foundation

protocol SendUserFeedBackUseCase: Sendable {
    func execute(with title: String, and description: String, tag: String) async -> Bool
}

extension SendUserFeedBackUseCase {
    func callAsFunction(with title: String, and description: String, tag: String) async -> Bool {
        await execute(with: title, and: description, tag: tag)
    }
}

final class SendUserFeedBack: SendUserFeedBackUseCase {
    private let feedBackService: FeedBackServiceProtocol
    private let extractLogsToData: ExtractLogsToDataUseCase
    private let getLogEntries: GetLogEntriesUseCase

    init(feedBackService: FeedBackServiceProtocol,
         extractLogsToData: ExtractLogsToDataUseCase,
         getLogEntries: GetLogEntriesUseCase) {
        self.feedBackService = feedBackService
        self.extractLogsToData = extractLogsToData
        self.getLogEntries = getLogEntries
    }

    func execute(with title: String, and description: String, tag: String) async -> Bool {
        let entries = try? await getLogEntries(for: .hostApp)
        let logData = try? await extractLogsToData(for: entries)
        return await feedBackService.send(with: title, and: description, tag: tag, more: logData)
    }
}
