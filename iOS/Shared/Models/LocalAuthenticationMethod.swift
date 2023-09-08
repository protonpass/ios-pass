//
// LocalAuthenticationMethod.swift
// Proton Pass - Created on 13/07/2023.
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

import LocalAuthentication

enum LocalAuthenticationMethod: Codable {
    case none, biometric, pin
}

enum LocalAuthenticationMethodUiModel {
    case none, biometric(LABiometryType), pin

    var iconSystemName: String? {
        if case let .biometric(type) = self {
            switch type {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            default:
                assertionFailure("Not usable biometric type")
                return nil
            }
        } else {
            return nil
        }
    }

    var title: String {
        switch self {
        case .none:
            return "No unlock".localized
        case let .biometric(type):
            switch type {
            case .faceID:
                return "Face ID".localized
            case .touchID:
                return "Touch ID".localized
            default:
                assertionFailure("Not usable biometric type")
                return ""
            }
        case .pin:
            return "PIN Code".localized
        }
    }

    var method: LocalAuthenticationMethod {
        switch self {
        case .none:
            return .none
        case .biometric:
            return .biometric
        case .pin:
            return .pin
        }
    }
}

extension LocalAuthenticationMethodUiModel: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.method == rhs.method
    }
}

extension LABiometryType {
    // We only use Face ID or Touch ID
    var usable: Bool {
        switch self {
        case .faceID, .touchID:
            return true
        default:
            return false
        }
    }

    var fallbackToPasscodeMessage: String {
        switch self {
        case .faceID:
            return "Use system passcode when Face ID fails".localized
        case .touchID:
            return "Use system passcode when Touch ID fails".localized
        default:
            assertionFailure("Not applicable")
            return ""
        }
    }
}
