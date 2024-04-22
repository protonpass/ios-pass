//
// Access.swift
// Proton Pass - Created on 16/10/2023.
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
//

import Foundation

public struct Access: Decodable, Equatable, Sendable {
    public let plan: Plan
    public var monitor: Monitor
    public let pendingInvites: Int
    public let waitingNewUserInvites: Int
    public let minVersionUpgrade: String?

    public init(plan: Plan,
                monitor: Monitor,
                pendingInvites: Int,
                waitingNewUserInvites: Int,
                minVersionUpgrade: String?) {
        self.plan = plan
        self.monitor = monitor
        self.pendingInvites = pendingInvites
        self.waitingNewUserInvites = waitingNewUserInvites
        self.minVersionUpgrade = minVersionUpgrade
    }
}

public extension Access {
    struct Monitor: Decodable, Equatable, Sendable {
        public let protonAddress: Bool
        public let aliases: Bool

        public init(protonAddress: Bool, aliases: Bool) {
            self.protonAddress = protonAddress
            self.aliases = aliases
        }
    }
}
