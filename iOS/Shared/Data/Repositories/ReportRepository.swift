//
// FeedBackService.swift
// Proton Pass - Created on 28/06/2023.
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

import Client
import Core
import Foundation

enum ReportRepositoryError: Error {
    case noUserData
}

// sourcery: AutoMockable
protocol ReportRepositoryProtocol: Sendable {
    func sendBug(with title: String,
                 and description: String,
                 optional logs: [String: URL]?) async throws -> Bool
    func sendFeedback(with title: String,
                      and description: String) async throws -> Bool
}

public final class ReportRepository: @unchecked Sendable, ReportRepositoryProtocol {
    private let apiManager: APIManagerProtocol
    private let logger: Logger

    public init(apiManager: APIManagerProtocol,
                logger: Logger) {
        self.logger = logger
        self.apiManager = apiManager
    }

    /// Sends a user bug report
    /// - Parameters:
    ///   - title: The bug title
    ///   - description: The bug description
    ///   - logs: The last user logs
    /// - Returns: `True` if the bug was sent correctly or and `Error` if not
    public func sendBug(with title: String,
                        and description: String,
                        optional logs: [String: URL]?) async throws -> Bool {
        guard let userData = apiManager.userData else {
            throw ReportRepositoryError.noUserData
        }
        let request = BugReportRequest(with: title, and: description, userData: userData)
        let endpoint = ReportsBugEndpoint(request: request)
        if let logs {
            return try await apiManager.apiService.exec(endpoint: endpoint, files: logs).isSuccessful
        } else {
            return try await apiManager.apiService.exec(endpoint: endpoint).isSuccessful
        }
    }

    /// Sends a user feedback
    /// - Parameters:
    ///   - title: The feedback title
    ///   - description: The feedback description
    /// - Returns: `True` if the  feedback was sent correctly or and `Error` if not
    public func sendFeedback(with title: String,
                             and description: String) async throws -> Bool {
        let request = FeedbackRequest(with: title, and: description)
        let endpoint = FeedbackEndpoint(request: request)
        return try await apiManager.apiService.exec(endpoint: endpoint).isSuccessful
    }
}
