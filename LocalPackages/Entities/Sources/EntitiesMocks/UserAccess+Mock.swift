//
// UserAccess+Mock.swift
// Proton Pass - Created on 17/12/2024.
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

public extension Plan {
    static func mock(
        type: String = "plus",
        internalName: String = "internal_mock_plan",
        displayName: String = "Mock Plan",
        hideUpgrade: Bool = false,
        manageAlias: Bool = true,
        trialEnd: Int? = 0,
        vaultLimit: Int? = 100,
        aliasLimit: Int? = 50,
        totpLimit: Int? = 10
    ) -> Plan {
        Plan(
            type: type,
            internalName: internalName,
            displayName: displayName,
            hideUpgrade: hideUpgrade,
            manageAlias: manageAlias,
            trialEnd: trialEnd,
            vaultLimit: vaultLimit,
            aliasLimit: aliasLimit,
            totpLimit: totpLimit
        )
    }
    static let mockBusinessPlan: Plan = .mock(type: "business")
    static let mockFreePlan: Plan = .mock(type: "free")
}

public extension UserAliasSyncData {
    static func mock(
        defaultShareID: String? = "mockShareID",
        aliasSyncEnabled: Bool = true,
        pendingAliasToSync: Int = 5
    ) -> UserAliasSyncData {
        UserAliasSyncData(
            defaultShareID: defaultShareID,
            aliasSyncEnabled: aliasSyncEnabled,
            pendingAliasToSync: pendingAliasToSync
        )
    }
}

public extension Access.Monitor {
    static func mock(
        protonAddress: Bool = true,
        aliases: Bool = true
    ) -> Access.Monitor {
        Access.Monitor(
            protonAddress: protonAddress,
            aliases: aliases
        )
    }
}

public extension Access {
    static func mock(
        plan: Plan = .mock(),
        monitor: Monitor = .mock(),
        pendingInvites: Int = 2,
        waitingNewUserInvites: Int = 3,
        minVersionUpgrade: String? = "1.0.0",
        userData: UserAliasSyncData = .mock()
    ) -> Access {
        Access(
            plan: plan,
            monitor: monitor,
            pendingInvites: pendingInvites,
            waitingNewUserInvites: waitingNewUserInvites,
            minVersionUpgrade: minVersionUpgrade,
            userData: userData
        )
    }
}

public extension UserAccess {
    static func mock(
        userId: String = "mockUserID",
        access: Access = .mock()
    ) -> UserAccess {
        UserAccess(
            userId: userId,
            access: access
        )
    }
}
