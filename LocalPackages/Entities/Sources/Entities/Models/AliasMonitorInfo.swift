//
// AliasMonitorInfo.swift
// Proton Pass - Created on 19/04/2024.
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

import Foundation

public struct AliasMonitorInfo: Sendable, Identifiable, Hashable {
    public let alias: ItemContent
    public let breaches: EmailBreaches?

    public init(alias: ItemContent, breaches: EmailBreaches?) {
        self.alias = alias
        self.breaches = breaches
    }

    public var id: String {
        alias.id
    }
}

extension AliasMonitorInfo: Breachable {
    public var email: String {
        alias.aliasEmail ?? ""
    }

    public var breachCounter: Int {
        breaches?.count ?? 0
    }

    public var lastBreachTime: Int? {
        guard let breaches = breaches?.breaches,
              let latestBreach = breaches.sorted(by: { $0.publishedAtDate > $1.publishedAtDate }).first
        else { return nil }
        return Int(latestBreach.publishedAtDate.timeIntervalSince1970)
    }
}
