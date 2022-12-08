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
            return "Turn on Autofill"
        case .autoFillEnabled:
            return "Autofill enabled"
        case .biometricAuthentication:
            return "Protect what matters most"
        case .biometricAuthenticationEnabled:
            return "Biometric authentication enabled"
        case .aliases:
            return "Protect your true email address"
        }
    }

    var description: String {
        switch self {
        case .autoFill, .autoFillEnabled:
            // swiftlint:disable:next line_length
            return "AutoFill allows you to automatically enter your passwords in Safari and other apps, in a really fast and easy way."
        case .biometricAuthentication, .biometricAuthenticationEnabled:
            return "Enable Face ID or Touch ID to shield your device from prying eyes."
        case .aliases:
            // swiftlint:disable:next line_length
            return "With email aliases, you can be anonymous online and protect your inbox against spams and phishing."
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .autoFill:
            return "Turn on"
        case .biometricAuthentication:
            return "Enable"
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
