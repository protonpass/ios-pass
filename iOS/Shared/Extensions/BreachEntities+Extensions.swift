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

import Entities
import Foundation
import Macro

extension ProtonAddress {
    var isMonitored: Bool {
        !flags.isFlagActive(.skipHealthCheckOrMonitoring)
    }
}

extension UserBreaches {
    var topTenBreachedAddresses: [ProtonAddress] {
        Array(addresses.filter { $0.isMonitored && $0.isBreached }
            .sorted { $0.breachCounter > $1.breachCounter }.prefix(10))
    }

    var numberOfBreachedProtonAddresses: Int {
        addresses.filter { $0.isMonitored && $0.isBreached }.count
    }
}

extension AliasMonitorInfo {
    var latestBreach: String {
        #localized("Latest breach on %@", breaches?.breaches.first?.breachDate ?? "")
    }
}

extension [AliasMonitorInfo] {
    var topTenBreachedAliases: [AliasMonitorInfo] {
        Array(filter { !$0.alias.item.skipHealthCheck && $0.alias.item.isBreached }
            .sorted {
                ($0.breaches?.count ?? Int.min) > ($1.breaches?.count ?? Int.min)
            }.prefix(10))
    }
}
