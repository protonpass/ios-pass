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
    case biometricAuthentication
    case biometricAuthenticationEnabled
    case aliases

    var title: String {
        switch self {
        case .autoFill:
            return "Enjoy the magic of AutoFill"
        case .autoFillEnabled:
            return "Ready to AutoFill"
        case .biometricAuthentication:
            return "Protect your most sensitive data"
        case .biometricAuthenticationEnabled:
            return "Face ID enabled"
        case .aliases:
            return "Don’t give spam a chance"
        }
    }

    var description: String {
        switch self {
        case .autoFill:
            // swiftlint:disable:next line_length
            return "Turn on AutoFill to let Proton Pass fill in login details for you⏤10 seconds that will save you hours."
        case .autoFillEnabled:
            // swiftlint:disable:next line_length
            return "When logging it to a site or service, tap the Proton Pass icon to automatically fill in your login details."
        case .biometricAuthentication:
            return "Set Proton Pass to unlock with your face or fingerprint so only you have access."
        case .biometricAuthenticationEnabled:
            return "Now you can unlock Proton Pass only when you need it⏤quickly and securely."
        case .aliases:
            // swiftlint:disable:next line_length
            return "Use email aliases to hide your actual email address and prevent spam from filling up your inbox."
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .autoFill:
            return "Go to Settings"
        case .biometricAuthentication:
            return "Enable FaceID"
        case .aliases:
            return "Get started"
        case .autoFillEnabled, .biometricAuthenticationEnabled:
            return "Next"
        }
    }

    var secondaryButtonTitle: String? {
        switch self {
        case .autoFill:
            return "Not now"
        case .biometricAuthentication:
            return "No thanks"
        case .autoFillEnabled, .biometricAuthenticationEnabled, .aliases:
            return nil
        }
    }
}
