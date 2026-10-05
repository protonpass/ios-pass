//
// GetAllSecurityAffectedLoginsTests.swift
// Proton Pass - Created on 05/10/2026.
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

import ClientMocks
import Entities
import EntitiesMocks
import Testing
import UseCases

@Suite(.tags(.useCase, .monitor))
struct GetAllSecurityAffectedLoginsTests {
    @Test func `weak passwords list only items whose weakness is still active`() throws {
        let weak = affected("weak", detected: [.weakPassword])
        let suppressed = affected("suppressed", detected: [.weakPassword], suppressed: [.weakPassword])
        let disabled = affected("disabled", detected: [.weakPassword], monitoringDisabled: true)
        let reused = affected("reused", detected: [.reusedPassword])

        let content = try content(for: .weakness(.weakPassword), items: [weak, suppressed, disabled, reused])

        #expect(content.keys.map(\.self) == [.weakPasswords])
        #expect(content[.weakPasswords]?.map(\.itemId) == ["weak"])
    }

    @Test func `no affected item gives no section`() throws {
        let content = try content(for: .weakness(.missing2FA),
                                  items: [affected("weak", detected: [.weakPassword])])
        #expect(content.isEmpty)
    }

    @Test func `reused passwords are grouped and lone passwords are dropped`() throws {
        let items = [
            affected("a1", detected: [.reusedPassword], reuseGroup: 1),
            affected("a2", detected: [.reusedPassword], reuseGroup: 1),
            affected("a3", detected: [.reusedPassword], reuseGroup: 1),
            affected("b1", detected: [.reusedPassword], reuseGroup: 2),
            affected("b2", detected: [.reusedPassword], reuseGroup: 2),
            affected("lone", detected: [.reusedPassword], reuseGroup: 3),
            affected("ungrouped", detected: [.reusedPassword], reuseGroup: nil)
        ]

        let content = try content(for: .weakness(.reusedPassword), items: items)

        let groups = content.map { section, items -> (Int?, Set<String>) in
            guard case let .reusedPasswords(key) = section else { return (nil, []) }
            return (key.numberOfTimeReused, Set(items.map(\.itemId)))
        }
        #expect(groups.count == 2)
        #expect(groups.contains { $0.0 == 3 && $0.1 == ["a1", "a2", "a3"] })
        #expect(groups.contains { $0.0 == 2 && $0.1 == ["b1", "b2"] })
    }

    @Test func `excluded items include partially suppressed and fully excluded items`() throws {
        let items = [
            affected("partial", detected: [.weakPassword, .missing2FA], suppressed: [.missing2FA]),
            affected("disabled", detected: [.weakPassword], monitoringDisabled: true),
            affected("monitored", detected: [.weakPassword])
        ]

        let content = try content(for: .excludedItems, items: items)

        #expect(Set(content[.excludedItems]?.map(\.itemId) ?? []) == ["partial", "disabled"])
    }

    @Test func `the excluded items section is present even when empty`() throws {
        let content = try content(for: .excludedItems, items: [])
        #expect(content == [.excludedItems: []])
    }
}

private extension GetAllSecurityAffectedLoginsTests {
    func content(for filter: MonitorListSection, items: [SecurityAffectedItem]) throws -> SecurityIssuesContent {
        let repository = PassMonitorRepositoryProtocolMock()
        repository.stubbedItemsWithSecurityIssues = .init(items)
        var received: SecurityIssuesContent?
        let cancellable = GetAllSecurityAffectedLogins(passMonitorRepository: repository)(for: filter)
            .sink { received = $0 }
        cancellable.cancel()
        return try #require(received)
    }

    func affected(_ itemId: String,
                  detected: Set<WeaknessKind>,
                  suppressed: Set<WeaknessKind> = [],
                  monitoringDisabled: Bool = false,
                  reuseGroup: Int? = nil) -> SecurityAffectedItem {
        let item = Item.random(itemId: itemId, state: .active, flags: monitoringDisabled ? 1 : 0)
        return SecurityAffectedItem(item: .random(shareId: "share-1", item: item),
                                    detected: detected,
                                    display: .mock(itemId: itemId, shareId: "share-1"),
                                    suppressedChecks: suppressed,
                                    reuseGroup: reuseGroup)
    }
}
