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
@preconcurrency import ProtonCoreLogin

/// Make an invitation and return the shared `Vault`
public protocol SendShareInviteUseCase: Sendable {
    func execute(with infos: [SharingInfos]) async throws -> Share
}

public extension SendShareInviteUseCase {
    func callAsFunction(with infos: [SharingInfos]) async throws -> Share {
        try await execute(with: infos)
    }
}

public final class SendShareInvite: @unchecked Sendable, SendShareInviteUseCase {
    private let createAndMoveItemToNewVault: any CreateAndMoveItemToNewVaultUseCase
    private let makeUnsignedSignatureForVaultSharing: any MakeUnsignedSignatureForVaultSharingUseCase
    private let shareInviteService: any ShareInviteServiceProtocol
    private let passKeyManager: any PassKeyManagerProtocol
    private let shareInviteRepository: any ShareInviteRepositoryProtocol
    private let userManager: any UserManagerProtocol
    private let syncEventLoop: any SyncEventLoopProtocol

    public init(createAndMoveItemToNewVault: any CreateAndMoveItemToNewVaultUseCase,
                makeUnsignedSignatureForVaultSharing: any MakeUnsignedSignatureForVaultSharingUseCase,
                shareInviteService: any ShareInviteServiceProtocol,
                passKeyManager: any PassKeyManagerProtocol,
                shareInviteRepository: any ShareInviteRepositoryProtocol,
                userManager: any UserManagerProtocol,
                syncEventLoop: any SyncEventLoopProtocol) {
        self.createAndMoveItemToNewVault = createAndMoveItemToNewVault
        self.makeUnsignedSignatureForVaultSharing = makeUnsignedSignatureForVaultSharing
        self.shareInviteService = shareInviteService
        self.passKeyManager = passKeyManager
        self.shareInviteRepository = shareInviteRepository
        self.userManager = userManager
        self.syncEventLoop = syncEventLoop
    }

    public func execute(with infos: [SharingInfos]) async throws -> Share {
        guard let baseInfo = infos.first else {
            throw PassError.sharing(.incompleteInformation)
        }
        let userData = try await userManager.getUnwrappedActiveUserData()
        let userId = userData.user.ID
        let share = try await getShare(userId: userId, from: baseInfo)
        let itemId = getItemId(from: baseInfo)
        let key: any ShareKeyProtocol = if baseInfo.shareTargetType == .vault {
            try await passKeyManager.getLatestShareKey(userId: userId, shareId: share.id)
        } else if let itemId {
            if share.shareType == .vault {
                try await passKeyManager.getLatestItemKey(userId: userId,
                                                          shareId: share.id,
                                                          itemId: itemId)
            } else {
                try await passKeyManager.getLatestShareKey(userId: userId, shareId: share.id)
            }
        } else {
            throw PassError.sharing(.failedEncryptionKeysFetching)
        }

        let inviteesData = try await infos.asyncCompactMap { try await generateInviteeData(userData: userData,
                                                                                           from: $0,
                                                                                           share: share,
                                                                                           shareKey: key) }

        let invited = try await shareInviteRepository.sendInvites(shareId: share.id,
                                                                  itemId: itemId,
                                                                  inviteesData: inviteesData,
                                                                  targetType: baseInfo.shareTargetType)

        if invited {
            syncEventLoop.forceSync()
            shareInviteService.resetShareInviteInformations()
            return share
        }

        throw PassError.sharing(.failedToInvite)
    }
}

private extension SendShareInvite {
    func getShare(userId: String, from info: SharingInfos) async throws -> Share {
        switch info.shareElement {
        case let .vault(vault):
            vault
        case let .item(_, item):
            item
        case let .new(vaultContent, itemContent):
            try await createAndMoveItemToNewVault(userId: userId, vault: vaultContent, itemContent: itemContent)
        }
    }

    func getItemId(from info: SharingInfos) -> String? {
        switch info.shareElement {
        case let .item(item, _):
            item.itemId
        default:
            nil
        }
    }

    func generateInviteeData(userData: UserData,
                             from info: SharingInfos,
                             share: Share,
                             shareKey: any ShareKeyProtocol) async throws -> InviteeData {
        let email = info.email
        if let key = info.receiverPublicKeys?.first {
            let signedKey = try CryptoUtils.encryptKeyForSharing(addressId: share.addressId,
                                                                 publicReceiverKey: key,
                                                                 userData: userData,
                                                                 key: shareKey)
            return .existing(email: email, keys: [signedKey], role: info.role)
        } else {
            let signature = try createAndSignSignature(addressId: share.addressId,
                                                       shareKey: shareKey,
                                                       email: email,
                                                       userData: userData)
            return .new(email: email, signature: signature, role: info.role)
        }
    }

    func createAndSignSignature(addressId: String,
                                shareKey: any ShareKeyProtocol,
                                email: String,
                                userData: UserData) throws -> String {
        guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: addressId,
                                                                 userData: userData).first else {
            throw PassError.crypto(.addressNotFound(addressID: addressId))
        }

        let signerKey = SigningKey(privateKey: addressKey.privateKey,
                                   passphrase: addressKey.passphrase)
        let unsignedSignature = makeUnsignedSignatureForVaultSharing(email: email,
                                                                     vaultKey: shareKey.keyData)
        let context = SignatureContext(value: Constants.newUserSharingSignatureContext,
                                       isCritical: true)

        return try Sign.signDetached(signingKey: signerKey,
                                     plainData: unsignedSignature,
                                     signatureContext: context)
            .unArmor().value.base64EncodedString()
    }
}
