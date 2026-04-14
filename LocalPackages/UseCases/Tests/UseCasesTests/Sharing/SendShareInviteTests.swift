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
import Combine
import Entities
import EntitiesMocks
import ProtonCoreLogin
import UseCases
import UseCasesMocks
import XCTest

final class SendShareInviteTests: XCTestCase {
    var sut: SendShareInviteUseCase!
    var createAndMoveItemToNewVault: CreateAndMoveItemToNewVaultUseCaseMock!
    var makeUnsignedSignatureForVaultSharing: MakeUnsignedSignatureForVaultSharingUseCase!
    var publicKeyRepository: PublicKeyRepositoryProtocolMock!
    var passKeyManager: PassKeyManagerProtocolMock!
    var shareInviteRepository: ShareInviteRepositoryProtocolMock!
    var userManager: UserManagerProtocolMock!
    var syncEventLoop: SyncEventLoopProtocolMock!

    override func setUp() {
        super.setUp()
        createAndMoveItemToNewVault = CreateAndMoveItemToNewVaultUseCaseMock()
        makeUnsignedSignatureForVaultSharing = MakeUnsignedSignatureForVaultSharing()
        publicKeyRepository = PublicKeyRepositoryProtocolMock()
        passKeyManager = PassKeyManagerProtocolMock()
        shareInviteRepository = ShareInviteRepositoryProtocolMock()
        userManager = UserManagerProtocolMock()
        syncEventLoop = SyncEventLoopProtocolMock()
    }

    @MainActor
    func testSendShareInvite_ShouldNotBeValid_BecauseOfVaultAddress() async throws {
        sut = SendShareInvite(createAndMoveItemToNewVault: createAndMoveItemToNewVault,
                              makeUnsignedSignatureForVaultSharing: makeUnsignedSignatureForVaultSharing,
                              shareInviteService: ShareInviteService(),
                              passKeyManager: passKeyManager,
                              shareInviteRepository: shareInviteRepository,
                              userManager: userManager,
                              syncEventLoop: syncEventLoop)
        publicKeyRepository.stubbedGetPublicKeysResult = [PublicKey(value: "value")]
        passKeyManager.stubbedGetLatestShareKeyResult = try DecryptedShareKey(shareId: "test", keyRotation: 1,
                                                                              keyData: Data.random())
        userManager.stubbedGetActiveUserDataResult = .preview
        let infos = SharingInfos(shareElement: .vault(.random()),
                                 email: "Test@test.com",
                                 destinationName: "Test",
                                 groupInfo: nil,
                                 role: .read,
                                 receiverPublicKeys: [PublicKey(value: "")],
                                 itemsNum: 100)
        do {
            _ = try await sut(with: [infos])
            XCTFail("Error needs to be thrown")
        } catch {
            XCTAssertTrue(error is PassError)
        }
    }
}
