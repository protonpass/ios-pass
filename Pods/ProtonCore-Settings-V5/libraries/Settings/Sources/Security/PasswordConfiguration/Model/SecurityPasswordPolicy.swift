//
//  SecurityPasswordPolicy.swift
//  ProtonCore-Settings - Created on 02.10.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

final class SecurityPasswordPolicy {
    // swiftlint:disable identifier_name
    private static var numbers_from4to421: String {
        "^[0-9]{4,21}$"
    }

    static var regex: NSRegularExpression {
        NSRegularExpression(for: numbers_from4to421)
    }

    func isRegexCompliant(password: String, regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: .zero, length: password.utf16.count)
        return regex.firstMatch(in: password, options: [], range: range) != nil
    }
}

extension NSRegularExpression {
    convenience init(for pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }

    func isRegexCompliant(for string: String) -> Bool {
        let range = NSRange(location: .zero, length: string.utf16.count)
        return self.firstMatch(in: string, options: [], range: range) != nil
    }
}
