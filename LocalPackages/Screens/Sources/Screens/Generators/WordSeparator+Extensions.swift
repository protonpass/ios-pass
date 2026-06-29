//
// WordSeparator+Extensions.swift
// Proton Pass - Created on 25/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Macro

public extension WordSeparator {
    var title: String {
        switch self {
        case .hyphens: #localized("Hyphens", bundle: .module)
        case .spaces: #localized("Spaces", bundle: .module)
        case .periods: #localized("Periods", bundle: .module)
        case .commas: #localized("Commas", bundle: .module)
        case .underscores: #localized("Underscores", bundle: .module)
        case .numbers: #localized("Numbers", bundle: .module)
        case .numbersAndSymbols: #localized("Numbers and Symbols", bundle: .module)
        }
    }
}
