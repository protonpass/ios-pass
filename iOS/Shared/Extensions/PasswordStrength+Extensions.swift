//
// PasswordStrength+Extensions.swift
// Proton Pass - Created on 28/11/2023.
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

import DesignSystem
import Entities
import Macro
import SwiftUI

extension PasswordStrength {
    var title: String {
        switch self {
        case .vulnerable:
            #localized("Vulnerable")
        case .weak:
            #localized("Weak")
        case .strong:
            #localized("Strong")
        }
    }

    var iconName: String {
        switch self {
        case .vulnerable:
            "xmark.shield.fill"
        case .weak:
            "exclamationmark.shield.fill"
        case .strong:
            "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .vulnerable:
            PassColor.signalDanger.toColor
        case .weak:
            PassColor.signalWarning.toColor
        case .strong:
            PassColor.signalSuccess.toColor
        }
    }
}

extension PasswordStrength? {
    func sectionTitle(reuseCount: Int?) -> String {
        if let self {
            if let reuseCount {
                #localized("Password") + " • " + self.title + " • " + "Reused" + " (\(reuseCount))"
            } else {
                #localized("Password") + " • " + self.title
            }
        } else {
            #localized("Password")
        }
    }

    var sectionTitleColor: Color {
        if let self {
            self.color
        } else {
            PassColor.textWeak.toColor
        }
    }
}
