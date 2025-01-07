//
// LoginItemsView+Mode.swift
// Proton Pass - Created on 27/02/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Macro

public extension LoginItemsView {
    enum Mode {
        case passkeyCreation
    }
}

extension LoginItemsView.Mode {
    var title: String {
        switch self {
        case .passkeyCreation:
            #localized("Create passkey", bundle: .module)
        }
    }

    var description: String {
        switch self {
        case .passkeyCreation:
            #localized("Select an existing login or create a new one.", bundle: .module)
        }
    }

    var allowCreation: Bool {
        switch self {
        case .passkeyCreation:
            true
        }
    }
}
