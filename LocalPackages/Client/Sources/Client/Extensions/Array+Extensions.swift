//
// Array+Extensions.swift
// Proton Pass - Created on 05/10/2023.
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

import Entities

public extension [Share] {
    /// This canAutoFill params has been computed on the BE side to determined if a vault should be accessible to
    /// use in autofill
    /// This should replace the previous client logic calculating the oldest 2 vaults of the user.
    var autofillAllowedVaults: [Share] {
        self.filter(\.canAutoFill)
    }

    var oldestOwned: Share? {
        if self.isEmpty {
            return nil
        }
        return self.filter(\.isOwner).min(by: { $0.createTime < $1.createTime })
    }

    var numberOfOwnedVault: Int {
        self.filter(\.isOwner).count
    }
}
