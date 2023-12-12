//
// ReportRepository.swift
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

import Core
import Foundation
import ProtonCoreLogin
import ProtonCoreServices

public enum ReportRepositoryError: Error {
    case noUserData
}

public enum ReportFileKey: String, CaseIterable {
    case hostApp = "File0"
    case autofill = "File1"
}

// sourcery: AutoMockable
public protocol ReportRepositoryProtocol: Sendable {
    func sendBug(with title: String,
                 and description: String,
                 optional logs: [String: URL]) async throws -> Bool
    func sendFeedback(with title: String,
                      and description: String) async throws -> Bool
}

public actor ReportRepository: @unchecked Sendable, ReportRepositoryProtocol {
    private let apiService: any APIService
    private let userDataProvider: any UserDataProvider
    private let logger: Logger

    public init(apiService: any APIService,
                userDataProvider: any UserDataProvider,
                logManager: any LogManagerProtocol) {
        logger = .init(manager: logManager)
        self.apiService = apiService
        self.userDataProvider = userDataProvider
    }
}

// periphery:ignore
extension UserData: @unchecked Sendable {}

public extension ReportRepository {
    /// Sends a user bug report
    /// - Parameters:
    ///   - title: The bug title
    ///   - description: The bug description
    ///   - logs: The last user logs
    /// - Returns: `True` if the bug was sent correctly or and `Error` if not
    func sendBug(with title: String,
                 and description: String,
                 optional logs: [String: URL]) async throws -> Bool {
        guard let userData = userDataProvider.getUserData() else {
            throw ReportRepositoryError.noUserData
        }
        let request = await BugReportRequest(with: title, and: description, userData: userData)
        let endpoint = ReportsBugEndpoint(request: request)
        if !logs.isEmpty {
            let result = try await apiService.exec(endpoint: endpoint, files: logs).isSuccessful
            cleanReportLogFiles(from: logs)
            return result
        } else {
            return try await apiService.exec(endpoint: endpoint).isSuccessful
        }
    }

    /// Sends a user feedback
    /// - Parameters:
    ///   - title: The feedback title
    ///   - description: The feedback description
    /// - Returns: `True` if the  feedback was sent correctly or and `Error` if not
    func sendFeedback(with title: String, and description: String) async throws -> Bool {
        let request = FeedbackRequest(with: title, and: description)
        let endpoint = FeedbackEndpoint(request: request)
        return try await apiService.exec(endpoint: endpoint).isSuccessful
    }
}

private extension ReportRepository {
    func cleanReportLogFiles(from logs: [String: URL]) {
        for key in ReportFileKey.allCases {
            if let fileUrl = logs[key.rawValue] {
                FileManager.default.removeIfExists(for: fileUrl)
            }
        }
    }
}
