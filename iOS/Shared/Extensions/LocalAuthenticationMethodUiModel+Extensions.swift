//
// LocalAuthenticationMethodUiModel+Extensions.swift
// Proton Pass - Created on 31/10/2023.
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

import Entities
import LocalAuthentication
import Macro

extension LocalAuthenticationMethodUiModel {
    var title: String {
        switch self {
        case .none:
            return #localized("No unlock")
        case let .biometric(type):
            switch type {
            case .faceID:
                return #localized("Face ID")
            case .touchID:
                return #localized("Touch ID")
            case .opticID:
                return #localized("Optic ID")
            default:
                assertionFailure("Not usable biometric type")
                return ""
            }
        case .pin:
            return #localized("PIN Code")
        }
    }

    var method: LocalAuthenticationMethod {
        switch self {
        case .none:
            .none
        case .biometric:
            .biometric
        case .pin:
            .pin
        }
    }
}

extension LocalAuthenticationMethodUiModel: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.method == rhs.method
    }
}
