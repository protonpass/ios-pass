//
// AliasSynchronizerTests.swift
// Proton Pass - Created on 21/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import ClientMocks
import Entities
import Testing
import TestingToolkit

@Suite(.tags(.synchronizer))
struct AliasSynchronizerTests {
    let accessRepository = AccessRepositoryProtocolMock()
    let aliasRepository = AliasRepositoryProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()
    var sut: (any AliasSynchronizerProtocol)!

    init() {
        sut = AliasSynchronizer(accessRepository: accessRepository,
                                aliasRepository: aliasRepository,
                                itemRepository: itemRepository)
    }
}

private struct Args {
    let access: Access
    let pendingAliases: [PaginatedPendingAliases]
    let result: Bool
    var createPendingAliasesItemInvokeCount: Int?

    static var aliasSyncNotEnabled: Self {
        .init(access: .init(plan: .mockFreePlan,
                            monitor: .mock(),
                            pendingInvites: 0,
                            waitingNewUserInvites: 0,
                            minVersionUpgrade: nil,
                            userData: .mock(aliasSyncEnabled: false)),
              pendingAliases: [],
              result: false)
    }

    static var aliasSyncEnabledButNoAliasesToSync: Self {
        .init(access: .init(plan: .mockFreePlan,
                            monitor: .mock(),
                            pendingInvites: 0,
                            waitingNewUserInvites: 0,
                            minVersionUpgrade: nil,
                            userData: .mock(aliasSyncEnabled: true,
                                            pendingAliasToSync: 0)),
              pendingAliases: [],
              result: false)
    }

    static var onePageSync: Self {
        .init(access: .init(plan: .mockFreePlan,
                            monitor: .mock(),
                            pendingInvites: 0,
                            waitingNewUserInvites: 0,
                            minVersionUpgrade: nil,
                            userData: .mock(aliasSyncEnabled: true,
                                            pendingAliasToSync: 10)),
              pendingAliases: [
                .init(total: 10,
                      lastToken: .random(),
                      aliases: .random(count: 10)),
                .init(total: 0, lastToken: .random(), aliases: [])
              ],
              result: true,
              createPendingAliasesItemInvokeCount: 1)
    }

    static var twoPageSync: Self {
        .init(access: .init(plan: .mockFreePlan,
                            monitor: .mock(),
                            pendingInvites: 0,
                            waitingNewUserInvites: 0,
                            minVersionUpgrade: nil,
                            userData: .mock(aliasSyncEnabled: true,
                                            pendingAliasToSync: 15)),
              pendingAliases: [
                .init(total: 10,
                      lastToken: .random(),
                      aliases: .random(count: 10)),
                .init(total: 5,
                      lastToken: .random(),
                      aliases: .random(count: 5)),
                .init(total: 0, lastToken: nil, aliases: [])
              ],
              result: true,
              createPendingAliasesItemInvokeCount: 2)
    }
}

private extension AliasSynchronizerTests {
    @Test("Sync aliases",
    arguments: [
        Args.aliasSyncNotEnabled,
        Args.aliasSyncEnabledButNoAliasesToSync,
        Args.onePageSync,
        Args.twoPageSync
    ])
    func sync(args: Args) async throws {
        let userId = String.random()
        accessRepository.stubbedGetAccessResult = .init(userId: userId,
                                                        access: args.access)

        itemRepository.stubbedCreatePendingAliasesItemResult = []

        if !args.pendingAliases.isEmpty {

        }

        var pendingAliases = args.pendingAliases
        aliasRepository.closureGetPendingAliasesToSync = {
            aliasRepository.stubbedGetPendingAliasesToSyncResult = pendingAliases.removeFirst()
        }

        let result = try await sut.sync(userId: userId)
        #expect(result == args.result)

        if let createPendingAliasesItemInvokeCount = args.createPendingAliasesItemInvokeCount {
            itemRepository.invokedCreatePendingAliasesItemCount = createPendingAliasesItemInvokeCount
        }
    }
}

extension PendingAlias: Randomable {
    public static func random() -> Self {
        .init(pendingAliasID: .random(),
              aliasEmail: .random(),
              aliasNote: .random())
    }
}
