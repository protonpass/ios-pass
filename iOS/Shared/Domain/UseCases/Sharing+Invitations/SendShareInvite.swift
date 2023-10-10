//
//
// SendShareInvite.swift
// Proton Pass - Created on 21/07/2023.
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
//

import Client
import Core
import CryptoKit
import Entities
import ProtonCoreCrypto
import ProtonCoreLogin
import UseCases

/// Make an invitation and return the shared `Vault`
protocol SendVaultShareInviteUseCase: Sendable {
    func execute(with infos: SharingInfos) async throws -> Vault
}

extension SendVaultShareInviteUseCase {
    func callAsFunction(with infos: SharingInfos) async throws -> Vault {
        try await execute(with: infos)
    }
}

final class SendVaultShareInvite: @unchecked Sendable, SendVaultShareInviteUseCase {
    private let createVault: CreateVaultUseCase
    private let moveItemsBetweenVaults: MoveItemsBetweenVaultsUseCase
    private let vaultsManager: VaultsManagerProtocol
    private let shareInviteService: ShareInviteServiceProtocol
    private let passKeyManager: PassKeyManagerProtocol
    private let shareInviteRepository: ShareInviteRepositoryProtocol
    private let userData: UserData
    private let syncEventLoop: SyncEventLoopProtocol

    init(createVault: CreateVaultUseCase,
         moveItemsBetweenVaults: MoveItemsBetweenVaultsUseCase,
         vaultsManager: VaultsManagerProtocol,
         shareInviteService: ShareInviteServiceProtocol,
         passKeyManager: PassKeyManagerProtocol,
         shareInviteRepository: ShareInviteRepositoryProtocol,
         userData: UserData,
         syncEventLoop: SyncEventLoopProtocol) {
        self.createVault = createVault
        self.moveItemsBetweenVaults = moveItemsBetweenVaults
        self.vaultsManager = vaultsManager
        self.shareInviteService = shareInviteService
        self.passKeyManager = passKeyManager
        self.shareInviteRepository = shareInviteRepository
        self.userData = userData
        self.syncEventLoop = syncEventLoop
    }

    func execute(with infos: SharingInfos) async throws -> Vault {
        guard let email = infos.email,
              let role = infos.role,
              let publicReceiverKeys = infos.receiverPublicKeys else {
            throw SharingError.incompleteInformation
        }

        let vault = try await createVaultIfNeccessary(infos: infos)

        let sharedKey = try await passKeyManager.getLatestShareKey(shareId: vault.shareId)

        guard let publicReceiverKey = publicReceiverKeys.first?.value else {
            throw SharingError.failedEncryptionKeysFetching
        }

        let signedKeys = try encryptKeys(addressId: vault.addressId,
                                         publicReceiverKey: publicReceiverKey,
                                         userData: userData,
                                         vaultKey: sharedKey)

        let invited = try await shareInviteRepository.sendInvite(shareId: vault.shareId,
                                                                 keys: [signedKeys],
                                                                 email: email,
                                                                 targetType: .vault,
                                                                 shareRole: role)

        if invited {
            syncEventLoop.forceSync()
            shareInviteService.resetShareInviteInformations()
            return vault
        }

        throw SharingError.failedToInvite
    }
}

private extension SendVaultShareInvite {
    func encryptKeys(addressId: String,
                     publicReceiverKey: String,
                     userData: UserData,
                     vaultKey: DecryptedShareKey) throws -> ItemKey {
        guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: addressId,
                                                                 userData: userData).first else {
            throw PPClientError.crypto(.addressNotFound(addressID: addressId))
        }

        let publicKey = ArmoredKey(value: publicReceiverKey)
        let signerKey = SigningKey(privateKey: addressKey.privateKey,
                                   passphrase: addressKey.passphrase)
        let context = SignatureContext(value: Constants.existingUserSharingSignatureContext,
                                       isCritical: true)

        let encryptedVaultKeyString = try Encryptor.encrypt(publicKey: publicKey,
                                                            clearData: vaultKey.keyData,
                                                            signerKey: signerKey,
                                                            signatureContext: context)
            .unArmor().value.base64EncodedString()

        return ItemKey(key: encryptedVaultKeyString, keyRotation: vaultKey.keyRotation)
    }

    func createVaultIfNeccessary(infos: SharingInfos) async throws -> Vault {
        guard let sharedVault = infos.vault else {
            throw SharingError.incompleteInformation
        }

        switch sharedVault {
        case let .existing(vault):
            return vault
        case let .new(vaultProtobuf, itemContent):
            do {
                if let vault = try await createVault(with: vaultProtobuf) {
                    try await moveItemsBetweenVaults(movingContext: .item(itemContent,
                                                                          newShareId: vault.shareId))
                    vaultsManager.refresh()
                    return vault
                } else {
                    throw SharingError.failedToCreateNewVault
                }
            } catch {
                throw SharingError.failedToCreateNewVault
            }
        }
    }
}
