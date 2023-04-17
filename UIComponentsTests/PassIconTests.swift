//
// PassIconTests.swift
// Proton Pass - Created on 17/04/2023.
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

@testable import UIComponents
import XCTest

final class PassIconTests: XCTestCase {
    // swiftlint:disable:next function_body_length
    func testGetIconss() {
        let expectation = expectation(description: "Should be able to get icons")

        _ = PassIcon.brandPass
        _ = PassIcon.brandReddit
        _ = PassIcon.brandTwitter

        _ = PassIcon.magnifyingGlass

        _ = PassIcon.onboardAliases
        _ = PassIcon.onboardAuthentication
        _ = PassIcon.onboardAuthenticationBackground
        _ = PassIcon.onboardAuthenticationEnabled
        _ = PassIcon.onboardAutoFillGradient
        _ = PassIcon.onboardAutoFillEnabled
        _ = PassIcon.onboardAutoFillStep1
        _ = PassIcon.onboardAutoFillStep2
        _ = PassIcon.onboardAutoFillStep3
        _ = PassIcon.onboardAutoFillStep4
        _ = PassIcon.onboardAutoFillStep5

        _ = PassIcon.passIcon
        _ = PassIcon.passTextLogo
        _ = PassIcon.swirls
        _ = PassIcon.trash

        _ = PassIcon.allVaults
        _ = PassIcon.vaultIcon1
        _ = PassIcon.vaultIcon2
        _ = PassIcon.vaultIcon3
        _ = PassIcon.vaultIcon4
        _ = PassIcon.vaultIcon5
        _ = PassIcon.vaultIcon6
        _ = PassIcon.vaultIcon7
        _ = PassIcon.vaultIcon8
        _ = PassIcon.vaultIcon9
        _ = PassIcon.vaultIcon10
        _ = PassIcon.vaultIcon11
        _ = PassIcon.vaultIcon12
        _ = PassIcon.vaultIcon13
        _ = PassIcon.vaultIcon14
        _ = PassIcon.vaultIcon15
        _ = PassIcon.vaultIcon16
        _ = PassIcon.vaultIcon17
        _ = PassIcon.vaultIcon18
        _ = PassIcon.vaultIcon19
        _ = PassIcon.vaultIcon20
        _ = PassIcon.vaultIcon21
        _ = PassIcon.vaultIcon22
        _ = PassIcon.vaultIcon23
        _ = PassIcon.vaultIcon24
        _ = PassIcon.vaultIcon25
        _ = PassIcon.vaultIcon26
        _ = PassIcon.vaultIcon27
        _ = PassIcon.vaultIcon28
        _ = PassIcon.vaultIcon29
        _ = PassIcon.vaultIcon30

        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
}
