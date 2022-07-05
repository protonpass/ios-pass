//
//  SecurityPasswordSelector.swift
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

final class SecurityPasswordSelector: PasswordSelector {
    private(set) var initialPasswordProposal: String?
    private(set) var confirmationPassword: String?

    func getPassword() -> Result<String, Error> {
        guard let initial = initialPasswordProposal else { return .failure(initialPasswordNotSet) }
        guard initial == confirmationPassword else { return .failure(passwordsDoNotMatch) }
        return .success(initial)
    }

    func setInitialPassword(to password: String) throws {
        confirmationPassword = nil
        initialPasswordProposal = nil
        guard SecurityPasswordPolicy.regex.isRegexCompliant(for: password) else { throw invalidPassword }

        initialPasswordProposal = password
    }

    func setConfirmationPassword(to password: String) throws {
        confirmationPassword = nil
        guard initialPasswordProposal != nil else { throw initialPasswordNotSet }
        guard SecurityPasswordPolicy.regex.isRegexCompliant(for: password) else { throw invalidPassword }

        confirmationPassword = password
    }
}
extension SecurityPasswordSelector {
    var passwordsDoNotMatch: NSError {
        return NSError(domain: "Passwords don't match", code: 0)
    }

    var invalidPassword: NSError {
        NSError(domain: "Invalid Password", code: 20)
    }

    var initialPasswordNotSet: NSError {
        NSError(domain: "Initial Password not set", code: 20)
    }
}
