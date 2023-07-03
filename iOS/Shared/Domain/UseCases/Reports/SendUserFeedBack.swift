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

/**
 The SendUserFeedBackUseCase protocol defines the contract for a use case that handles sending user feedback.
 It inherits from the `Sendable protocol, which allows the use case to be executed asynchronously.
 */
protocol SendUserFeedBackUseCase: Sendable {
    /**
     Executes the use case to send user feedback with the specified title and description.

     - Parameters:
       - title: The title of the user feedback.
       - description: The description of the user feedback.

     - Returns: A `Bool` value indicating whether the feedback was sent successfully or not.

     - Throws: An error if an issue occurs while sending the feedback.
     */
    func execute(with title: String, and description: String) async throws -> Bool
}

extension SendUserFeedBackUseCase {
    /**
     Convenience method that allows the use case to be invoked as a function, simplifying its usage.

     - Parameters:
       - title: The title of the user feedback.
       - description: The description of the user feedback.

     - Returns: A `Bool` value indicating whether the feedback was sent successfully or not.

     - Throws: An error if an issue occurs while sending the feedback.
     */
    func callAsFunction(with title: String, and description: String) async throws -> Bool {
        try await execute(with: title, and: description)
    }
}

/**
 The SendUserFeedBack class is an implementation of the SendUserFeedBackUseCase protocol.
 It provides functionality for sending user feedback.
 */
final class SendUserFeedBack: SendUserFeedBackUseCase {
    private let reportRepository: ReportRepositoryProtocol

    init(reportRepository: ReportRepositoryProtocol) {
        self.reportRepository = reportRepository
    }

    /**
     Executes the use case to send user feedback with the specified title and description.

     - Parameters:
       - title: The title of the user feedback.
       - description: The description of the user feedback.

     - Returns: A `Bool` value indicating whether the feedback was sent successfully or not.

     - Throws: An error if an issue occurs while sending the feedback.
     */
    func execute(with title: String, and description: String) async throws -> Bool {
        try await reportRepository.sendFeedback(with: title, and: description)
    }
}
