//
// OnboardingViewState.swift
// Proton Pass - Created on 08/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Foundation

enum OnboardingViewState {
    case autoFill
    case autoFillEnabled
    case biometricAuthenticationTouchID
    case biometricAuthenticationFaceID
    case faceIDEnabled
    case touchIDEnabled
    case aliases

    var title: String {
        switch self {
        case .autoFill:
            return "Enjoy the magic of AutoFill"
        case .autoFillEnabled:
            return "Log in to apps instantly"
        case .biometricAuthenticationFaceID, .biometricAuthenticationTouchID:
            return "Protect your most sensitive data"
        case .faceIDEnabled:
            return "Face ID enabled"
        case .touchIDEnabled:
            return "Touch ID enabled"
        case .aliases:
            return "Control what lands in your inbox"
        }
    }

    var description: String {
        switch self {
        case .autoFill:
            // swiftlint:disable:next line_length
            return "Turn on AutoFill to let Proton Pass fill in login details for you⏤10 seconds that will save you hours."
        case .autoFillEnabled:
            // swiftlint:disable:next line_length
            return "When logging in to a site or service, tap the Proton Pass icon to automatically fill in your login details."
        case .biometricAuthenticationFaceID, .biometricAuthenticationTouchID:
            return "Set Proton Pass to unlock with your face or fingerprint so only you have access."
        case .faceIDEnabled, .touchIDEnabled:
            return "Now you can unlock Proton Pass only when you need it⏤quickly and securely."
        case .aliases:
            return "Stop sharing your real email address. Instead hide it with email aliases⏤a Proton Pass exclusive."
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .autoFill:
            return "Go to Settings"
        case .biometricAuthenticationTouchID:
            return "Enable Touch ID"
        case .biometricAuthenticationFaceID:
            return "Enable Face ID"
        case .aliases:
            return "Start using Proton Pass"
        case .autoFillEnabled, .faceIDEnabled, .touchIDEnabled:
            return "Next"
        }
    }

    var secondaryButtonTitle: String? {
        switch self {
        case .autoFill, .biometricAuthenticationFaceID, .biometricAuthenticationTouchID:
            return "Not now"
        case .aliases, .autoFillEnabled, .faceIDEnabled, .touchIDEnabled:
            return nil
        }
    }
}
