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
import ProtonCoreLogin
import Testing
import UseCases

@Suite(.tags(.cxp))
struct ImportCxpItemsTests {
    let userManager = UserManagerProtocolMock()
    let accessRepository = AccessRepositoryProtocolMock()
    let organizationRepository = OrganizationRepositoryProtocolMock()
    let shareRepository = ShareRepositoryProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()

    init() {
        userManager.stubbedGetAllUsersResult = []
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mock(vaultLimit: nil)))
        organizationRepository.stubbedGetOrganizationResult = .init(canUpdate: false, settings: nil)
        shareRepository.stubbedGetSharesResult = []
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
                                     ])
        let progress = OSAllocatedUnfairLock(initialState: [Int]())
        let sut = makeSut()

        try await sut(userId: "user", result: result, defaultVaultName: "Default") { count in
            progress.withLock { $0.append(count) }
        }

        #expect(await shareRepository.invokedCreateVaultCount == 2)
        #expect(await shareRepository.invokedCreateVaultParameters?.vault.name == "Default")
        #expect(itemRepository.invokedImportItemsCount == 2)
        #expect(itemRepository.invokedImportItemsParameters?.contents.map(\.name) == ["Note 3"])
        #expect(progress.withLock { $0 } == [1, 3])
    }

    @Test func `import nothing when the plan vault limit would be exceeded`() async {
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mock(vaultLimit: 2)))
        shareRepository.stubbedGetSharesResult = [.vault()]
        let sut = makeSut()

        await #expect(throws: PassError.importer(.vaultLimitReached)) {
            try await sut(userId: "user", result: .twoVaults, defaultVaultName: "Default", onProgress: nil)
        }
        #expect(await shareRepository.invokedCreateVaultCount == 0)
    }

    @Test func `import nothing when the organization disallows any of the needed vaults`() async {
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mockBusinessPlan))
        shareRepository.stubbedGetSharesResult = [.vault()]
        let sut = makeSut(allowance: VaultCountAllowance(maxVaultCount: 2))

        await #expect(throws: PassError.importer(.vaultCreationNotAllowed)) {
            try await sut(userId: "user", result: .twoVaults, defaultVaultName: "Default", onProgress: nil)
        }
        #expect(await shareRepository.invokedCreateVaultCount == 0)
    }

    @Test func `organization policy is ignored for non business plans`() async throws {
        let sut = makeSut(allowance: VaultCountAllowance(maxVaultCount: 0))

        try await sut(userId: "user", result: .twoVaults, defaultVaultName: "Default", onProgress: nil)

        #expect(await shareRepository.invokedCreateVaultCount == 2)
    }
}

private extension ImportCxpItemsTests {
    func makeSut(allowance: any CheckVaultCreationAllowanceUseCase = VaultCountAllowance(maxVaultCount: .max))
        -> any ImportCxpItemsUseCase {
        ImportCxpItems(userManager: userManager,
                       accessRepository: accessRepository,
                       organizationRepository: organizationRepository,
                       shareRepository: shareRepository,
                       itemRepository: itemRepository,
                       checkVaultCreationAllowance: allowance)
    }
}

private struct VaultCountAllowance: CheckVaultCreationAllowanceUseCase {
    let maxVaultCount: Int

    func execute(userData: UserData?, organization: Entities.Organization?, vaultCount: Int) -> Bool {
        vaultCount < maxVaultCount
    }
}

private extension CxpImportResult {
    static var twoVaults: Self {
        .init(exporterName: "Exporter",
              vaults: [
                  .init(vault: nil, items: [.note(name: "Note 1")]),
                  .init(vault: nil, items: [.note(name: "Note 2")])
              ])
    }
}

private extension SymmetricallyEncryptedShare {
    static func vault() -> Self {
        .init(encryptedContent: nil, share: .random(targetType: Int64(TargetType.vault.rawValue)))
    }
}

private extension ItemContentProtobuf {
    static func note(name: String) -> Self {
        .init(name: name, note: "", itemUuid: UUID().uuidString, data: .note, customFields: [])
    }
}
