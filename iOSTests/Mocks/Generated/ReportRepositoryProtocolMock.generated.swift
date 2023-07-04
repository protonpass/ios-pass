// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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
// swiftlint:disable all

@testable import Proton_Pass
import Client
import Core
import Foundation

final class ReportRepositoryProtocolMock: @unchecked Sendable, ReportRepositoryProtocol {
    // MARK: - sendBug
    var sendBugWithAndOptionalThrowableError: Error?
    var closureSendBug: () -> () = {}
    var invokedSendBug = false
    var invokedSendBugCount = 0
    var invokedSendBugParameters: (title: String, description: String, logs: [String: URL])?
    var invokedSendBugParametersList = [(title: String, description: String, logs: [String: URL])]()
    var stubbedSendBugResult: Bool!

    func sendBug(with title: String, and description: String, optional logs: [String: URL]) async throws -> Bool {
        invokedSendBug = true
        invokedSendBugCount += 1
        invokedSendBugParameters = (title, description, logs)
        invokedSendBugParametersList.append((title, description, logs))
        if let error = sendBugWithAndOptionalThrowableError {
            throw error
        }
        closureSendBug()
        return stubbedSendBugResult
    }
    // MARK: - sendFeedback
    var sendFeedbackWithAndThrowableError: Error?
    var closureSendFeedback: () -> () = {}
    var invokedSendFeedback = false
    var invokedSendFeedbackCount = 0
    var invokedSendFeedbackParameters: (title: String, description: String)?
    var invokedSendFeedbackParametersList = [(title: String, description: String)]()
    var stubbedSendFeedbackResult: Bool!

    func sendFeedback(with title: String, and description: String) async throws -> Bool {
        invokedSendFeedback = true
        invokedSendFeedbackCount += 1
        invokedSendFeedbackParameters = (title, description)
        invokedSendFeedbackParametersList.append((title, description))
        if let error = sendFeedbackWithAndThrowableError {
            throw error
        }
        closureSendFeedback()
        return stubbedSendFeedbackResult
    }
}
