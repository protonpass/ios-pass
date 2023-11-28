//
// GetPasswordStrengthTests.swift
// Proton Pass - Created on 28/11/2023.
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

@testable import UseCases
import Entities
import PassRustCore
import XCTest

class GetPasswordStrengthTests: XCTestCase {
    // Mock implementation of PasswordScorerProtocol for testing
    class MockPasswordScorer: PasswordScorerProtocol {
        var mockScore: PasswordScore

        init(mockScore: PasswordScore) {
            self.mockScore = mockScore
        }

        func checkScore(password: String) -> PasswordScore {
            // Return the mock score for testing
            mockScore
        }
    }

    func testGetPasswordStrengthStrong() {
        // Arrange
        let password = "strong_password"
        let passwordScorer = MockPasswordScorer(mockScore: .strong)
        let getPasswordStrength = GetPasswordStrength(passwordScorer: passwordScorer)

        // Act
        let result = getPasswordStrength.execute(password: password)

        // Assert
        XCTAssertEqual(result, .strong, "Expected strong password strength")
    }

    func testGetPasswordStrengthWeak() {
        // Arrange
        let password = "weak_password"
        let passwordScorer = MockPasswordScorer(mockScore: .weak)
        let getPasswordStrength = GetPasswordStrength(passwordScorer: passwordScorer)

        // Act
        let result = getPasswordStrength.execute(password: password)

        // Assert
        XCTAssertEqual(result, .weak, "Expected weak password strength")
    }

    func testGetPasswordStrengthVulnerable() {
        // Arrange
        let password = "vulnerable_password"
        let passwordScorer = MockPasswordScorer(mockScore: .veryDangerous)
        let getPasswordStrength = GetPasswordStrength(passwordScorer: passwordScorer)

        // Act
        let result = getPasswordStrength.execute(password: password)

        // Assert
        XCTAssertEqual(result, .vulnerable, "Expected vulnerable password strength")
    }
}
