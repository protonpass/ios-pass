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

@Suite(.tags(.entity))
struct LAErrorTests {
    @Test(arguments: [LAError.Code.notInteractive,
                      .appCancel,
                      .biometryLockout,
                      .biometryNotAvailable,
                      .biometryNotEnrolled])
    func `an error raised before any face is judged reaches no verdict`(code: LAError.Code) {
        #expect(LAError(code).reachedNoVerdict)
    }

    @Test(arguments: [LAError.Code.authenticationFailed,
                      .userCancel,
                      .userFallback,
                      .systemCancel])
    func `an error that can follow a rejected face consumes an attempt`(code: LAError.Code) {
        #expect(LAError(code).consumesUnlockAttempt)
    }

    @Test(arguments: [LAError.Code.passcodeNotSet,
                      .invalidContext])
    func `any other error consumes an attempt`(code: LAError.Code) {
        #expect(LAError(code).consumesUnlockAttempt)
    }

    @Test func `an LAErrorDomain error for notInteractive does not consume an attempt`() {
        let error: any Error = NSError(domain: LAError.errorDomain, code: LAError.Code.notInteractive.rawValue)
        #expect(!error.consumesUnlockAttempt)
    }

    @Test func `a non local authentication error consumes an attempt`() {
        let error: any Error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError)
        #expect(error.consumesUnlockAttempt)
    }
}
