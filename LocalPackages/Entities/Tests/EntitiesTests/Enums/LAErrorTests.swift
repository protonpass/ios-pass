//
// LAErrorTests.swift
// Proton Pass - Created on 18/08/2026.
// Copyright (c) 2026 Proton Technologies AG
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

@testable import Entities
import LocalAuthentication
import Testing

@Suite("LAError Tests")
struct LAErrorTests {
    @Test("Errors raised without ever asking the user reach no verdict",
          arguments: [LAError.Code.notInteractive,
                      .systemCancel,
                      .appCancel,
                      .userCancel,
                      .userFallback])
    func reachedNoVerdict_whenPromptNeverAnswered_returnsTrue(code: LAError.Code) {
        #expect(LAError(code).reachedNoVerdict)
    }

    @Test("Errors carrying an actual outcome do reach a verdict",
          arguments: [LAError.Code.authenticationFailed,
                      .biometryLockout,
                      .biometryNotAvailable,
                      .biometryNotEnrolled,
                      .passcodeNotSet,
                      .invalidContext])
    func reachedNoVerdict_whenOutcomeIsKnown_returnsFalse(code: LAError.Code) {
        #expect(!LAError(code).reachedNoVerdict)
    }

    @Test("notInteractive is the documented -1004 \"Caller is not running foreground\" code")
    func notInteractive_hasCodeMinus1004() {
        #expect(LAError.Code.notInteractive.rawValue == -1004)
    }
}
