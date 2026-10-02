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
                      .systemCancel,
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
                      .passcodeNotSet,
                      .invalidContext])
    func `an error that may follow a judged face reaches a verdict`(code: LAError.Code) {
        #expect(!LAError(code).reachedNoVerdict)
    }
}
