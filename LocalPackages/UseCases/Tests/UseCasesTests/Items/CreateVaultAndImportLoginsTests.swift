//
// CreateVaultAndImportLoginsTests.swift
// Proton Pass - Created on 12/10/2026.
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
import UseCases

@Suite(.tags(.useCase))
struct CreateVaultAndImportLoginsTests {
    let shareRepository = ShareRepositoryProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()

    init() {
        shareRepository.stubbedCreateVaultResult = .random(shareID: "share")
    }

    @Test func `create the vault and import the logins when allowed`() async throws {
        let allowance = VaultCreationAllowanceStub()
        let sut = makeSut(allowance: allowance)

        try await sut(userId: "user", logins: [], vaultContent: .defaultVault)

        #expect(allowance.requestedVaultCounts.withLock { $0 } == [1])
        #expect(await shareRepository.invokedCreateVaultCount == 1)
        #expect(itemRepository.invokedImportLoginsParameters?.shareId == "share")
    }

    @Test(arguments: [
        (VaultCreationAllowance.vaultLimitReached, PassError.importer(.vaultLimitReached)),
        (.notAllowedByOrganization, PassError.importer(.vaultCreationNotAllowed))
    ])
    func `import nothing when the vault can not be created`(allowance: VaultCreationAllowance,
                                                            expectedError: PassError) async {
        let sut = makeSut(allowance: VaultCreationAllowanceStub(allowance: allowance))

        await #expect(throws: expectedError) {
            try await sut(userId: "user", logins: [], vaultContent: .defaultVault)
        }
        #expect(await shareRepository.invokedCreateVaultCount == 0)
        #expect(itemRepository.invokedImportLoginsCount == 0)
    }
}

private extension CreateVaultAndImportLoginsTests {
    func makeSut(allowance: VaultCreationAllowanceStub) -> any CreateVaultAndImportLoginsUseCase {
        CreateVaultAndImportLogins(shareRepository: shareRepository,
                                   itemRepository: itemRepository,
                                   checkVaultCreationAllowance: allowance)
    }
}
