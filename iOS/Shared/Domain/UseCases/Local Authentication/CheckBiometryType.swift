//
// CheckBiometryType.swift
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

/// Determine the supported `LABiometryType` of the device
protocol CheckBiometryTypeUseCase: Sendable {
    func execute(for policy: LAPolicy, context: LAContext) throws -> LABiometryType
}

extension CheckBiometryTypeUseCase {
    func callAsFunction(for policy: LAPolicy, context: LAContext) throws -> LABiometryType {
        try execute(for: policy, context: context)
    }
}

final class CheckBiometryType: CheckBiometryTypeUseCase {
    init() {}

    func execute(for policy: LAPolicy, context: LAContext) throws -> LABiometryType {
        var error: NSError?
        context.canEvaluatePolicy(policy, error: &error)
        if let error {
            throw error
        } else {
            return context.biometryType
        }
    }
}

extension LABiometryType {
    struct UiModel {
        public let title: String
        public let icon: String?
    }

    var title: UiModel? {
        switch self {
        case .faceID:
            return .init(title: "Face ID", icon: "faceid")
        case .touchID:
            return .init(title: "Touch ID", icon: "touchid")
        case .none:
            return .init(title: "Device passcode", icon: nil)
        default:
            return nil
        }
    }
}
