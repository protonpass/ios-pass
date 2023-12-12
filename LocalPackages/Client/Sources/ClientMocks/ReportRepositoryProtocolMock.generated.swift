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

import Client
import Core
import Foundation
import ProtonCoreLogin
import ProtonCoreServices

public final class ReportRepositoryProtocolMock: @unchecked Sendable, ReportRepositoryProtocol {

    public init() {}

    // MARK: - sendBug
    public var sendBugWithAndOptionalThrowableError1: Error?
    public var closureSendBug: () -> () = {}
    public var invokedSendBugfunction = false
    public var invokedSendBugCount = 0
    public var invokedSendBugParameters: (title: String, description: String, logs: [String: URL])?
    public var invokedSendBugParametersList = [(title: String, description: String, logs: [String: URL])]()
    public var stubbedSendBugResult: Bool!

    public func sendBug(with title: String, and description: String, optional logs: [String: URL]) async throws -> Bool {
        invokedSendBugfunction = true
        invokedSendBugCount += 1
        invokedSendBugParameters = (title, description, logs)
        invokedSendBugParametersList.append((title, description, logs))
        if let error = sendBugWithAndOptionalThrowableError1 {
            throw error
        }
        closureSendBug()
        return stubbedSendBugResult
    }
    // MARK: - sendFeedback
    public var sendFeedbackWithAndThrowableError2: Error?
    public var closureSendFeedback: () -> () = {}
    public var invokedSendFeedbackfunction = false
    public var invokedSendFeedbackCount = 0
    public var invokedSendFeedbackParameters: (title: String, description: String)?
    public var invokedSendFeedbackParametersList = [(title: String, description: String)]()
    public var stubbedSendFeedbackResult: Bool!

    public func sendFeedback(with title: String, and description: String) async throws -> Bool {
        invokedSendFeedbackfunction = true
        invokedSendFeedbackCount += 1
        invokedSendFeedbackParameters = (title, description)
        invokedSendFeedbackParametersList.append((title, description))
        if let error = sendFeedbackWithAndThrowableError2 {
            throw error
        }
        closureSendFeedback()
        return stubbedSendFeedbackResult
    }
}
