//
// SendUserFeedBackTests.swift
// Proton Pass - Created on 03/07/2023.
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

import XCTest
@testable import Proton_Pass

final class SendUserFeedBackTests: XCTestCase {
    var sut: SendUserFeedBackUseCase!
    var repositoryMock: ReportRepositoryProtocolMock!
    
    override func setUp() {
        super.setUp()
        repositoryMock = ReportRepositoryProtocolMock()
        sut = SendUserFeedBack(reportRepository: repositoryMock)
    }

    func testSendUserFeedback() async throws {
        repositoryMock.stubbedSendFeedbackResult = true
        let response = try await sut(with: "Test", and: "Feedback description")
        XCTAssertTrue(response)
        let params = try XCTUnwrap(repositoryMock.invokedSendFeedbackParameters)
        XCTAssertEqual(params.0, "Test")
        XCTAssertEqual(params.1, "Feedback description")
    }
}
