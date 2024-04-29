//
// BreachEntities+Extensions.swift
// Proton Pass - Created on 22/04/2024.
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

import DesignSystem
import Entities
import Foundation
import Macro

extension UserBreaches {
    var topBreachedAddresses: [ProtonAddress] {
        Array(addresses
            .filter { !$0.monitoringDisabled && $0.isBreached }
            .sorted { $0.breachCounter > $1.breachCounter }
            .prefix(DesignConstant.previewBreachItemCount))
    }

    var numberOfBreachedProtonAddresses: Int {
        addresses.filter { !$0.monitoringDisabled && $0.isBreached }.count
    }
}

extension AliasMonitorInfo {
    var latestBreach: String {
        #localized("Latest breach on %@", breaches?.breaches.first?.breachDate ?? "")
    }
}
