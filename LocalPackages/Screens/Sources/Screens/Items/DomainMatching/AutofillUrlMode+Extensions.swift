//
// AutofillUrlMode+Extensions.swift
// Proton Pass - Created on 22/06/2026.
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
//

import Entities
import Macro

public extension AutofillUrlMode {
    /// `nil` for a mode added to the protobuf after this build: it has no name to show and
    /// must not be offered as a choice, but the raw value is still round-tripped on save.
    var title: String? {
        switch self {
        case .default:
            #localized("Parent domain and subdomains", bundle: .module)

        case .exact:
            #localized("Exact (sub) domain", bundle: .module)

        case .never:
            #localized("Never fill on this website", bundle: .module)

        case .startWith:
            #localized("Starts with", bundle: .module)

        case .pattern:
            #localized("URL wildcard pattern", bundle: .module)

        case .regularExpression:
            #localized("Regular expression", bundle: .module)

        case .exactPath:
            #localized("Exact URL matching", bundle: .module)

        case .unrecognized:
            nil
        }
    }
}
