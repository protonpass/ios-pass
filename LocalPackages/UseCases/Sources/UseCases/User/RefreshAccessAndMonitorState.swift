//
// RefreshAccessAndMonitorState.swift
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
//

import Client
import Entities
import Foundation

public protocol RefreshAccessAndMonitorStateUseCase: Sendable {
    func execute(userId: String) async throws
}

public extension RefreshAccessAndMonitorStateUseCase {
    func callAsFunction(userId: String) async throws {
        try await execute(userId: userId)
    }
}

public final class RefreshAccessAndMonitorState: @unchecked Sendable, RefreshAccessAndMonitorStateUseCase {
    private let accessRepository: any AccessRepositoryProtocol
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let getAllAliases: any GetAllAliasesUseCase
    private let getBreachesForAlias: any GetBreachesForAliasUseCase
    private let stream: MonitorStateStream

    public init(accessRepository: any AccessRepositoryProtocol,
                passMonitorRepository: any PassMonitorRepositoryProtocol,
                getAllAliases: any GetAllAliasesUseCase,
                getBreachesForAlias: any GetBreachesForAliasUseCase,
                stream: MonitorStateStream) {
        self.accessRepository = accessRepository
        self.passMonitorRepository = passMonitorRepository
        self.getAllAliases = getAllAliases
        self.getBreachesForAlias = getBreachesForAlias
        self.stream = stream
    }

    public func execute(userId: String) async throws {
        async let getAccess = accessRepository.refreshAccess(userId: userId)
        async let refreshUserBreaches = passMonitorRepository.refreshUserBreaches()
        async let refreshSecurityChecks: () = passMonitorRepository.refreshSecurityChecks()
        async let getAllAliases = getAllAliases(userId: userId)
        let (access, userBreaches, aliases, _) = try await (getAccess, refreshUserBreaches, getAllAliases,
                                                            refreshSecurityChecks)
        let breachedAliases = aliases.filter(\.item.isBreachedAndMonitored)
        var breachCount = userBreaches.emailsCount

        if access.access.monitor.aliases {
            breachCount += breachedAliases.count
        }

        let hasWeaknesses = passMonitorRepository.weaknessStats.value.hasWeakOrReusedPasswords
        var latestBreach: LatestBreachDomainInfo?

        if let info = userBreaches.latestBreach {
            latestBreach = LatestBreachDomainInfo(domain: info.domain, date: info.formattedDateDescription)
        } else if let alias = breachedAliases.first {
            let breachInfo = try await getBreachesForAlias(shareId: alias.shareId, itemId: alias.itemId)
            if let firstBreach = breachInfo.breaches.first {
                latestBreach = LatestBreachDomainInfo(domain: firstBreach.name,
                                                      date: firstBreach.breachDate)
            }
        }

        updateState(isFreeUser: access.access.plan.isFreeUser,
                    breachCount: breachCount,
                    hasWeaknesses: hasWeaknesses,
                    latestBreach: latestBreach)
    }
}

private extension RefreshAccessAndMonitorState {
    func updateState(isFreeUser: Bool,
                     breachCount: Int,
                     hasWeaknesses: Bool,
                     latestBreach: LatestBreachDomainInfo?) {
        let state = switch (isFreeUser, breachCount > 0, hasWeaknesses) {
        case (true, false, false):
            MonitorState.inactive(.noBreaches)
        case (true, false, true):
            MonitorState.inactive(.noBreachesButWeakOrReusedPasswords)
        case (true, true, _):
            MonitorState.inactive(.breachesFound(breachCount, latestBreach))
        case (false, false, false):
            MonitorState.active(.noBreaches)
        case (false, false, true):
            MonitorState.active(.noBreachesButWeakOrReusedPasswords)
        case (false, true, _):
            MonitorState.active(.breachesFound(breachCount, latestBreach))
        }
        stream.send(state)
    }
}
