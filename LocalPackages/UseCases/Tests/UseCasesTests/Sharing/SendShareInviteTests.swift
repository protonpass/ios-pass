//
// SendShareInviteTests.swift
// Proton Pass - Created on 01/12/2025.
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

import Client
import ClientMocks
import Entities
import EntitiesMocks
import Foundation
import ProtonCoreLogin
import Testing
import UseCases
import UseCasesMocks

@Suite(.tags(.useCase))
struct SendShareInviteTests {
    @MainActor
    @Test func `sending an invite fails when the vault address cannot be found`() async throws {
        let passKeyManager = PassKeyManagerProtocolMock()
        let userManager = UserManagerProtocolMock()
        let sut = SendShareInvite(createAndMoveItemToNewVault: CreateAndMoveItemToNewVaultUseCaseMock(),
                                  makeUnsignedSignatureForVaultSharing: MakeUnsignedSignatureForVaultSharing(),
                                  shareInviteService: ShareInviteService(),
                                  passKeyManager: passKeyManager,
                                  shareInviteRepository: ShareInviteRepositoryProtocolMock(),
                                  userManager: userManager,
                                  syncEventLoop: SyncEventLoopProtocolMock())
        passKeyManager.stubbedGetLatestShareKeyResult = try DecryptedShareKey(shareId: "test",
                                                                              keyRotation: 1,
                                                                              keyData: Data.random())
        userManager.stubbedGetActiveUserDataResult = .preview
        let infos = SharingInfos(shareElement: .vault(.random()),
                                 email: "Test@test.com",
                                 destinationName: "Test",
                                 groupInfo: nil,
                                 role: .read,
                                 receiverPublicKeys: [PublicKey(value: "")],
                                 itemsNum: 100)

        await #expect(throws: PassError.self) {
            _ = try await sut(with: [infos])
        }
    }
}
