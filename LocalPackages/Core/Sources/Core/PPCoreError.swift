//
// PPCoreError.swift
// Proton Pass - Created on 07/02/2023.
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

import Foundation

/// Proton Pass core module related errors.
public enum PPCoreError: Error, CustomDebugStringConvertible, Sendable {
    case biometryTypeNotInitialized
    case failedToConvertBase64StringToData(String)
    case failedToRandomizeData
    case totp(TOTPDataCurruptionReason)

    public var debugDescription: String {
        switch self {
        case .biometryTypeNotInitialized:
            "Biometry type not initialized"
        case let .failedToConvertBase64StringToData(string):
            "Failed to convert base 64 string to data \"\(string)\""
        case .failedToRandomizeData:
            "Failed to randomize data"
        case let .totp(reason):
            reason.debugDescription
        }
    }
}

public extension PPCoreError {
    enum TOTPDataCurruptionReason: CustomDebugStringConvertible, Sendable {
        case unsupportedOTP
        case failedToDecodeSecret
        case failedToInitializeTOTPObject

        public var debugDescription: String {
            switch self {
            case .unsupportedOTP:
                "Unsupported OTP type (not TOTP)"
            case .failedToDecodeSecret:
                "Failed to decode secret"
            case .failedToInitializeTOTPObject:
                "Failed to initialize TOTP object"
            }
        }
    }
}
