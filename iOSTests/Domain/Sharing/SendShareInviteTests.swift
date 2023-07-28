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

import XCTest
import ProtonCore_Login
import Entities
@testable import Proton_Pass
@testable import Client

final class SendShareInviteTests: XCTestCase {
    var sut: SendVaultShareInviteUseCase!
    var publicKeyRepository: PublicKeyRepositoryProtocolMock!
    var passKeyManager: PassKeyManagerProtocolMock!
    var shareInviteRepository: ShareInviteRepositoryProtocolMock!
    
    override func setUp() {
        super.setUp()
        publicKeyRepository = PublicKeyRepositoryProtocolMock()
        passKeyManager = PassKeyManagerProtocolMock()
        shareInviteRepository = ShareInviteRepositoryProtocolMock()
        sut = SendVaultShareInvite(passKeyManager: passKeyManager,
                              shareInviteRepository: shareInviteRepository,
                              userData: UserData.mock)
    }

    func testSendShareInvite_ShouldBeNotBeValid_missingInfos() async throws {
        var infos = SharingInfos(vault: nil, email: nil, role: nil, receiverPublicKeys: nil, itemsNum: nil)
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
        let vault = Vault(id: "uhppq5QrsteiLDPAogeigTxEthMQ695gHXCiUdGgzWfwA6O4Ac9M9EDmR4CbM45SfAyhpLWqsSoU9RdSrxGAhA",
                          shareId: "y3f09sYakL5JFBA_7sNFZv0Xut6y-rvwTn-RMGWVOyuoKqb04RkiQGRjt5ULy-5-SlO-Ly2sfcijLcW1dqAdRA==",
                          addressId: "fANeSjpLbBu4DCGmPpsNMq5roCKQZNqNFDTSFnasuQX_g4imqjQ2imcEhoONECMEd-ruB10N9XWdD9WL-ciXnw==",
                          name: "Bear",
                          description: "",
                          displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences(),
                          isPrimary: false,
                          isOwner: true)
        var infos = SharingInfos(vault: vault, email: "Test@test.com", role: .read, receiverPublicKeys: [PublicKey(value: "")], itemsNum: 100)
        do {
            _ = try await sut(with: infos)
            XCTFail("Error needs to be thrown")
        } catch {
            XCTAssertTrue(error is PPClientError)
        }
    }
}
