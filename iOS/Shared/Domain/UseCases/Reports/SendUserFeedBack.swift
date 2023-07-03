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
    func execute(with title: String, and description: String) async throws -> Bool
}

extension SendUserFeedBackUseCase {
    func callAsFunction(with title: String, and description: String) async throws -> Bool {
        try await execute(with: title, and: description)
    }
}

final class SendUserFeedBack: SendUserFeedBackUseCase {
    private let reportRepository: ReportRepositoryProtocol

    init(reportRepository: ReportRepositoryProtocol) {
        self.reportRepository = reportRepository
    }

    func execute(with title: String, and description: String) async throws -> Bool {
        try await reportRepository.sendFeedback(with: title, and: description)
    }
}
