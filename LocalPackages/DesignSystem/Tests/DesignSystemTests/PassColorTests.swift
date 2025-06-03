//
// PassColorTests.swift
// Proton Pass - Created on 05/04/2023.
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

@testable import DesignSystem
import XCTest

final class PassColorTests: XCTestCase {
    // swiftlint:disable:next function_body_length
    func testGetColors() {
        let expectation = expectation(description: "Should be able to get colors")
        _ = PassColor.inputBackgroundNorm
        _ = PassColor.inputBorderNorm

        _ = PassColor.interactionNorm
        _ = PassColor.interactionNormMajor1
        _ = PassColor.interactionNormMajor2
        _ = PassColor.interactionNormMinor1
        _ = PassColor.interactionNormMajor2

        // Backgrounds
        _ = PassColor.backdrop
        _ = PassColor.backgroundMedium
        _ = PassColor.backgroundNorm
        _ = PassColor.backgroundStrong
        _ = PassColor.backgroundWeak
        _ = PassColor.tabBarBackground

        _ = PassColor.newBackgroundStrong

        // Items
        _ = PassColor.aliasInteractionNorm
        _ = PassColor.aliasInteractionNormMajor1
        _ = PassColor.aliasInteractionNormMajor2
        _ = PassColor.aliasInteractionNormMinor1
        _ = PassColor.aliasInteractionNormMinor2

        _ = PassColor.cardInteractionNorm
        _ = PassColor.cardInteractionNormMajor1
        _ = PassColor.cardInteractionNormMajor2
        _ = PassColor.cardInteractionNormMinor1
        _ = PassColor.cardInteractionNormMinor2

        _ = PassColor.loginInteractionNorm
        _ = PassColor.loginInteractionNormMajor1
        _ = PassColor.loginInteractionNormMajor2
        _ = PassColor.loginInteractionNormMinor1
        _ = PassColor.loginInteractionNormMinor2

        _ = PassColor.noteInteractionNorm
        _ = PassColor.noteInteractionNormMajor1
        _ = PassColor.noteInteractionNormMajor2
        _ = PassColor.noteInteractionNormMinor1
        _ = PassColor.noteInteractionNormMinor2

        _ = PassColor.passwordInteractionNorm
        _ = PassColor.passwordInteractionNormMajor1
        _ = PassColor.passwordInteractionNormMajor2
        _ = PassColor.passwordInteractionNormMinor1
        _ = PassColor.passwordInteractionNormMinor2

        _ = PassColor.customItemBackground

        // Signals
        _ = PassColor.signalDanger
        _ = PassColor.signalInfo
        _ = PassColor.signalSuccess
        _ = PassColor.signalWarning

        // Texts
        _ = PassColor.textDisabled
        _ = PassColor.textHint
        _ = PassColor.textInvert
        _ = PassColor.textNorm
        _ = PassColor.textWeak

        // Vaults
        _ = PassColor.vaultChestnutRose
        _ = PassColor.vaultDeYork
        _ = PassColor.vaultHeliotrope
        _ = PassColor.vaultJordyBlue
        _ = PassColor.vaultLavenderMagenta
        _ = PassColor.vaultMarigoldYellow
        _ = PassColor.vaultMauvelous
        _ = PassColor.vaultMercury
        _ = PassColor.vaultPorsche
        _ = PassColor.vaultWaterLeaf

        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
}
