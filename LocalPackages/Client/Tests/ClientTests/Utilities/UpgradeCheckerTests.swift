//
// UpgradeCheckerTests.swift
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

import Client
import ClientMocks
import Entities
import EntitiesMocks
import Testing

private final class LimitationCounterStub: LimitationCounterProtocol {
    let aliasCount: Int
    let vaultsCount: Int
    let totpCount: Int

    init(aliasCount: Int = 0, vaultsCount: Int = 0, totpCount: Int = 0) {
        self.aliasCount = aliasCount
        self.vaultsCount = vaultsCount
        self.totpCount = totpCount
    }

    func getAliasCount() async -> Int { aliasCount }
    func getSharesCount() async -> Int { 0 }
    func getVaultsCount() async -> Int { vaultsCount }
    func getTOTPCount() async -> Int { totpCount }
}

private struct TOTPCheckerStub: TOTPCheckerProtocol {
    let threshold: Int64?

    func totpCreationDateThreshold(numberOfTotp: Int) async throws -> Int64? { threshold }
}

@Suite(.tags(.utilities))
struct UpgradeCheckerTests {
    @Test func `alias limitation is nil when aliases are unlimited`() async throws {
        let sut = makeSUT(plan: .mock(aliasLimit: nil), counter: .init(aliasCount: 99))
        #expect(try await sut.aliasLimitation() == nil)
    }

    @Test func `alias limitation reports the current count against the plan limit`() async throws {
        let sut = makeSUT(plan: .mock(aliasLimit: 10), counter: .init(aliasCount: 7))

        let limitation = try #require(try await sut.aliasLimitation())

        #expect(limitation.count == 7)
        #expect(limitation.limit == 10)
    }

    @Test(arguments: [
        (Int?.none, 100, true),
        (2, 1, true),
        (2, 2, false),
        (2, 3, false)
    ])
    func `more vaults are allowed only while below the vault limit`(limit: Int?,
                                                                     vaultsCount: Int,
                                                                     expected: Bool) async throws {
        let sut = makeSUT(plan: .mock(vaultLimit: limit), counter: .init(vaultsCount: vaultsCount))
        #expect(try await sut.canCreateMoreVaults() == expected)
    }

    @Test(arguments: [
        (Int?.none, 100, true),
        (10, 9, true),
        (10, 10, false)
    ])
    func `more 2FA logins are allowed only while below the totp limit`(limit: Int?,
                                                                        totpCount: Int,
                                                                        expected: Bool) async throws {
        let sut = makeSUT(plan: .mock(totpLimit: limit), counter: .init(totpCount: totpCount))
        #expect(try await sut.canHaveMoreLoginsWith2FA() == expected)
    }

    @Test(arguments: [
        (Int?.none, Int64?.some(10), Int64(50), true),
        (10, nil, 50, true),
        (10, 50, 50, true),
        (10, 50, 51, false)
    ])
    func `a totp token shows only for items created up to the threshold`(limit: Int?,
                                                                          threshold: Int64?,
                                                                          creationDate: Int64,
                                                                          expected: Bool) async throws {
        let sut = makeSUT(plan: .mock(totpLimit: limit), threshold: threshold)
        #expect(try await sut.canShowTOTPToken(creationDate: creationDate) == expected)
    }

    @Test(arguments: [("free", true), ("plus", false), ("business", false)])
    func `only plans that are neither plus nor business are free`(type: String, expected: Bool) async throws {
        let sut = makeSUT(plan: .mock(type: type))
        #expect(try await sut.isFreeUser() == expected)
    }
}

private extension UpgradeCheckerTests {
    func makeSUT(plan: Plan,
                 counter: LimitationCounterStub = .init(),
                 threshold: Int64? = nil) -> UpgradeChecker {
        let accessRepository = AccessRepositoryProtocolMock()
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: plan))
        return UpgradeChecker(accessRepository: accessRepository,
                              counter: counter,
                              totpChecker: TOTPCheckerStub(threshold: threshold))
    }
}
