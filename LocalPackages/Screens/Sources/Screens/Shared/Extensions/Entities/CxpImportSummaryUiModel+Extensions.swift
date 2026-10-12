//
// CxpImportSummaryUiModel+Extensions.swift
// Proton Pass - Created on 03/10/2026.
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

extension CxpImportSummaryUiModel.Category {
    var title: String {
        switch self {
        case .login:
            ItemContentType.login.filterTitle

        case .totp:
            #localized("TOTP codes", bundle: .module)

        case .note:
            ItemContentType.note.filterTitle

        case .passkey:
            #localized("Passkeys", bundle: .module)

        case .alias:
            ItemContentType.alias.filterTitle

        case .custom:
            ItemContentType.custom.filterTitle

        case .identity:
            ItemContentType.identity.filterTitle

        case .creditCard:
            ItemContentType.creditCard.filterTitle
        }
    }
}
