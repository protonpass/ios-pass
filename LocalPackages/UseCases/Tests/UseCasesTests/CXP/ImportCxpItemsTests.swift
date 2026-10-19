//
// ImportCxpItemsTests.swift
// Proton Pass - Created on 02/10/2026.
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
import Foundation
import os
import Testing
import UseCases

@Suite(.tags(.cxp))
struct ImportCxpItemsTests {
    let shareRepository = ShareRepositoryProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()

    init() {
        shareRepository.stubbedCreateVaultResult = .random(shareID: "share")
        itemRepository.stubbedImportItemsOnProgressResult = (1, ())
    }

    @Test func `create one vault per collection and skip empty ones`() async throws {
        let result = CxpImportResult(exporterName: "Exporter",
                                     vaults: [
                                         .init(vault: .init(name: "Personal",
                                                            description: "",
                                                            color: .color2,
                                                            icon: .icon2),
                                               items: [.note(name: "Note 1"), .note(name: "Note 2")]),
                                         .init(vault: .init(name: "Empty",
                                                            description: "",
                                                            color: .color1,
                                                            icon: .icon1),
                                               items: []),
                                         .init(vault: nil, items: [.note(name: "Note 3")])
                                     ],
                                     hasUnsupportedItems: false)
        let progress = OSAllocatedUnfairLock(initialState: [Int]())
        let sut = makeSut()

        try await sut(userId: "user", result: result, defaultVaultContent: .defaultVault) { count in
            progress.withLock { $0.append(count) }
        }

        #expect(await shareRepository.invokedCreateVaultCount == 2)
        #expect(await shareRepository.invokedCreateVaultParameters?.vault.name == "Default")
        #expect(itemRepository.invokedImportItemsCount == 2)
        #expect(itemRepository.invokedImportItemsParameters?.contents.map(\.name) == ["Note 3"])
        #expect(progress.withLock { $0 } == [1, 3])
    }

    @Test func `check allowance only for the vaults that will be created`() async throws {
        let allowance = VaultCreationAllowanceStub()
        let result = CxpImportResult(exporterName: "Exporter",
                                     vaults: CxpImportResult.twoVaults.vaults + [.init(vault: nil, items: [])],
                                     hasUnsupportedItems: false)
        let sut = makeSut(allowance: allowance)

        try await sut(userId: "user", result: result, defaultVaultContent: .defaultVault, onProgress: nil)

        #expect(allowance.requestedVaultCounts.withLock { $0 } == [2])
    }

    @Test func `number the vaults created for items outside any collection`() async throws {
        let sut = makeSut()

        try await sut(userId: "user", result: .twoVaults, defaultVaultContent: .defaultVault, onProgress: nil)

        #expect(await shareRepository.invokedCreateVaultCount == 2)
        #expect(await shareRepository.invokedCreateVaultParameters?.vault.name == "Default (2)")
    }

    @Test(arguments: [
        (VaultCreationAllowance.vaultLimitReached, PassError.importer(.vaultLimitReached)),
        (.notAllowedByOrganization, PassError.importer(.vaultCreationNotAllowed))
    ])
    func `import nothing when the vaults can not all be created`(allowance: VaultCreationAllowance,
                                                                 expectedError: PassError) async {
        let sut = makeSut(allowance: VaultCreationAllowanceStub(allowance: allowance))

        await #expect(throws: expectedError) {
            try await sut(userId: "user", result: .twoVaults, defaultVaultContent: .defaultVault, onProgress: nil)
        }
        #expect(await shareRepository.invokedCreateVaultCount == 0)
    }
}

private extension ImportCxpItemsTests {
    func makeSut(allowance: any CheckVaultCreationAllowanceUseCase = VaultCreationAllowanceStub())
        -> any ImportCxpItemsUseCase {
        ImportCxpItems(shareRepository: shareRepository,
                       itemRepository: itemRepository,
                       checkVaultCreationAllowance: allowance)
    }
}

struct VaultCreationAllowanceStub: CheckVaultCreationAllowanceUseCase {
    var allowance = VaultCreationAllowance.allowed
    let requestedVaultCounts = OSAllocatedUnfairLock(initialState: [Int]())

    func callAsFunction(userId: String, newVaultCount: Int) -> VaultCreationAllowance {
        requestedVaultCounts.withLock { $0.append(newVaultCount) }
        return allowance
    }
}

private extension CxpImportResult {
    static var twoVaults: Self {
        .init(exporterName: "Exporter",
              vaults: [
                  .init(vault: nil, items: [.note(name: "Note 1")]),
                  .init(vault: nil, items: [.note(name: "Note 2")])
              ],
              hasUnsupportedItems: false)
    }
}

private extension ItemContentProtobuf {
    static func note(name: String) -> Self {
        .init(name: name, note: "", itemUuid: UUID().uuidString, data: .note, customFields: [])
    }
}

private extension VaultContent {
    static var defaultVault: Self {
        .init(name: "Default", description: "", color: .color1, icon: .icon1)
    }
}
