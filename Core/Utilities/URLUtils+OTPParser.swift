//
// URLUtils+OTPParser.swift
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

public extension URLUtils {
    enum OTPParser {}
}

public extension URLUtils.OTPParser {
    enum Error: Swift.Error, Equatable {
        case invalidScheme(String?)
        case invalidHost(String?)
        case tooManyPaths
        case missingLabel
        case missingSecret

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.invalidScheme(lScheme), .invalidScheme(rScheme)):
                return lScheme == rScheme
            case let (.invalidHost(lHost), .invalidHost(rHost)):
                return lHost == rHost
            case (.tooManyPaths, .tooManyPaths),
                (.missingLabel, .missingLabel),
                (.missingSecret, .missingSecret):
                return true
            default:
                return false
            }
        }
    }
}

public extension URLUtils.OTPParser {
    static func parse(url: URL) throws -> OTPComponents {
        guard let scheme = url.scheme, scheme == "otpauth" else {
            throw Error.invalidScheme(url.scheme)
        }

        guard let host = url.host,
              let type = OTPComponents.OTPType(rawString: host) else {
            throw Error.invalidHost(url.host)
        }

        let paths = url.pathComponents.filter { $0 != "/" }

        if paths.count > 1 {
            throw Error.tooManyPaths
        }

        guard let label = paths.first else {
            throw Error.missingLabel
        }

        guard let secret = url["secret"] else {
            throw Error.missingSecret
        }

        let algorithm = OTPComponents.Algorithm(rawString: url["algorithm"] ?? "") ?? .sha1
        let digits = UInt8(url["digits"] ?? "") ?? 6
        let period = UInt8(url["period"] ?? "") ?? 30

        return .init(type: type,
                     secret: secret,
                     label: label,
                     issuer: url["issuer"],
                     algorithm: algorithm,
                     digits: digits,
                     period: period)
    }
}
