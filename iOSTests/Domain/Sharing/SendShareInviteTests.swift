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
import UseCases
@testable import Proton_Pass
@testable import Client

final class SendShareInviteTests: XCTestCase {
    var sut: SendVaultShareInviteUseCase!
    var createAndMoveItemToNewVault: CreateAndMoveItemToNewVaultUseCaseMock!
    var publicKeyRepository: PublicKeyRepositoryProtocolMock!
    var passKeyManager: PassKeyManagerProtocolMock!
    var shareInviteRepository: ShareInviteRepositoryProtocolMock!
    var syncEventLoop: SyncEventLoopProtocolMock!

    override func setUp() {
        super.setUp()
        createAndMoveItemToNewVault = CreateAndMoveItemToNewVaultUseCaseMock()
        publicKeyRepository = PublicKeyRepositoryProtocolMock()
        passKeyManager = PassKeyManagerProtocolMock()
        shareInviteRepository = ShareInviteRepositoryProtocolMock()
        syncEventLoop = SyncEventLoopProtocolMock()
        sut = SendVaultShareInvite(createAndMoveItemToNewVault: createAndMoveItemToNewVault,
                                   shareInviteService: ShareInviteService(),
                                   passKeyManager: passKeyManager,
                                   shareInviteRepository: shareInviteRepository,
                                   userData: UserData.mock,
                                   syncEventLoop: syncEventLoop)
    }

    func testSendShareInvite_ShouldBeNotBeValid_missingInfos() async throws {
        let infos = SharingInfos(vault: nil, email: nil, role: nil, receiverPublicKeys: nil, itemsNum: nil)
        do {
            _ = try await sut(with: infos)
            XCTFail("Error needs to be thrown")
        } catch {
            XCTAssertEqual(error as! SharingError, SharingError.incompleteInformation)
        }
    }
    
    func testSendShareInvite_ShouldNotBeValid_BecauseOfVaultAddress() async throws {
        publicKeyRepository.stubbedGetPublicKeysResult = [PublicKey(value: "value")]
        passKeyManager.stubbedGetLatestShareKeyResult = DecryptedShareKey(shareId: "test", keyRotation: 1, keyData: try! Data.random())
        let infos = SharingInfos(vault: .existing(.random()),
                                 email: "Test@test.com",
                                 role: .read,
                                 receiverPublicKeys: [PublicKey(value: "")],
                                 itemsNum: 100)
        do {
            _ = try await sut(with: infos)
            XCTFail("Error needs to be thrown")
        } catch {
            XCTAssertTrue(error is PPClientError)
        }
    }
}

extension Vault {
    static func random() -> Self {
        .init(id: .random(),
              shareId: .random(),
              addressId: .random(),
              name: .random(),
              description: .random(),
              displayPreferences: .init(),
              isPrimary: false,
              isOwner: false,
              shareRole: .read,
              members: 0,
              maxMembers: 10,
              newUserPendingInvites: 0,
              shared: false,
              createTime: 0)
    }
}
