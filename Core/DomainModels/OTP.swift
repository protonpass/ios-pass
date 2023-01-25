//
// OTP.swift
// Proton Pass - Created on 18/01/2023.
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

public struct OTPComponents {
    public enum OTPType {
        case totp, hotp

        public init?(rawString: String) {
            switch rawString.uppercased() {
            case "TOTP": self = .totp
            case "HOTP": self = .hotp
            default: return nil
            }
        }
    }

    public enum Algorithm {
        case sha1
        case sha256
        case sha512

        public init?(rawString: String) {
            switch rawString.uppercased() {
            case "SHA1": self = .sha1
            case "SHA256": self = .sha256
            case "SHA512": self = .sha512
            default: return nil
            }
        }
    }

    public let type: OTPType
    public let secret: String
    public let label: String
    public let issuer: String?
    public let algorithm: Algorithm
    public let digits: UInt8
    public let period: UInt8

    public init(type: OTPType,
                secret: String,
                label: String,
                issuer: String?,
                algorithm: Algorithm,
                digits: UInt8,
                period: UInt8) {
        self.type = type
        self.secret = secret
        self.label = label
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }
}
