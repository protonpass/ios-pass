//
// SendShareInviteTests.swift
// Proton Pass - Created on 26/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Combine
import XCTest
import ProtonCoreLogin
import Entities
import EntitiesMocks
import UseCases
import UseCasesMocks
@testable import Proton_Pass
import Client
import ClientMocks

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
        sut = SendShareInvite(createAndMoveItemToNewVault: createAndMoveItemToNewVault,
                                   makeUnsignedSignatureForVaultSharing: makeUnsignedSignatureForVaultSharing,
                                   shareInviteService: ShareInviteService(),
                                   passKeyManager: passKeyManager,
                                   shareInviteRepository: shareInviteRepository,
                                   userManager: userManager,
                                   syncEventLoop: syncEventLoop)
    }

    func testSendShareInvite_ShouldNotBeValid_BecauseOfVaultAddress() async throws {
        publicKeyRepository.stubbedGetPublicKeysResult = [PublicKey(value: "value")]
        passKeyManager.stubbedGetLatestShareKeyResult = DecryptedShareKey(shareId: "test", keyRotation: 1, keyData: try! Data.random())
        userManager.stubbedGetActiveUserDataResult = .preview
        let infos = SharingInfos(shareElement: .vault(.random()),
                                 email: "Test@test.com",
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
