//
//
// AcceptInvitation.swift
// Proton Pass - Created on 31/07/2023.
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
import Entities
import ProtonCoreAuthentication
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreNetworking

public protocol AcceptInvitationUseCase: Sendable {
    /// Accept an invite and optionally return an item content in order to display after accepting
    func callAsFunction(userData: UserData, invite: Invite) async throws -> ItemContent?
}

public struct AcceptInvitation: AcceptInvitationUseCase {
    private let inviteRepository: any InviteRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let getEmailPublicKey: any GetEmailPublicKeyUseCase
    private let getInviteDecryptionKeys: GetInviteDecryptionKeysUseCase
    private let logger: Logger

    public init(inviteRepository: any InviteRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                getEmailPublicKey: any GetEmailPublicKeyUseCase,
                getInviteDecryptionKeys: GetInviteDecryptionKeysUseCase,
                logManager: any LogManagerProtocol) {
        self.inviteRepository = inviteRepository
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.getEmailPublicKey = getEmailPublicKey
        self.getInviteDecryptionKeys = getInviteDecryptionKeys
        logger = .init(manager: logManager)
    }

    public func callAsFunction(userData: UserData, invite: Invite) async throws -> ItemContent? {
        let inviteDebugInfo = "email \(invite.invitedEmail), token \(invite.inviteToken)"
        logger.trace("Start accepting for invite \(inviteDebugInfo)")
        let encrytedKeys = try await encryptKeys(userData: userData, invite: invite)
        logger.trace("Finished encrypting keys for invite \(inviteDebugInfo)")
        let userId = userData.user.ID

        let share = try await inviteRepository.acceptInvite(userId: userId, invite: invite, keys: encrytedKeys)
        // Remove right after accepting regardless of the outcome of subsequent fetches
        // Because re-accepting wouldn't work anyway
        try await inviteRepository.removeCachedInvite(userId: userId, invite: invite)
        if let share {
            try await shareRepository.upsertShares(userId: userId, shares: [share])

            switch share.shareType {
            case .item:
                logger.trace("Fetching shared item for item invite \(inviteDebugInfo)")
                return try await itemRepository.getSharedItem(userId: userId, share: share)

            case .vault:
                logger.trace("Fetching items for vault invite \(inviteDebugInfo)")
                try await itemRepository.refreshItems(userId: userId, shareId: share.shareId)

            case .unknown:
                break
            }
        }
        return nil
    }
}

struct TransformKeyConfig {
    let publicKey: ArmoredKey
    let signerKey: SigningKey
}

private extension AcceptInvitation {
    func encryptKeys(userData: UserData, invite: Invite) async throws -> [ItemKey] {
        do {
            async let addressKeysProcess = try getInviteDecryptionKeys(invite: invite)
            async let inviterPublicKeysProcess = try getEmailPublicKey(with: invite.inviterEmail)

            let (addressKeys, inviterPublicKeys) = try await (addressKeysProcess,
                                                              inviterPublicKeysProcess)

            let armoredInviterPublicKeys = inviterPublicKeys.map { ArmoredKey(value: $0.value) }
            let config = try getConfig(invite: invite, addressKeys: addressKeys, userData: userData)

            return try invite.keys.map { key in
                try transformKey(key: key,
                                 addressKeys: addressKeys,
                                 armoredInviterPublicKeys: armoredInviterPublicKeys,
                                 config: config)
            }
        } catch {
            logger.error(error)
            throw error
        }
    }

    func transformKey(key: ItemKey,
                      addressKeys: [DecryptionKey],
                      armoredInviterPublicKeys: [ArmoredKey],
                      config: TransformKeyConfig) throws -> ItemKey {
        guard let decodeKey = key.key.base64Decode() else {
            throw PassError.sharing(.cannotDecode)
        }

        let armoredEncryptedKeyData = try CryptoUtils.armorMessage(decodeKey)
        let armorMessage = ArmoredMessage(value: armoredEncryptedKeyData)
        let context = VerificationContext(value: Constants.SignatureContext.existingUserSharing,
                                          required: .always)

        let decode: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: addressKeys,
                                                                  value: armorMessage,
                                                                  verificationKeys: armoredInviterPublicKeys,
                                                                  verificationContext: context)

        let verifiedContent = try decode.verifiedContent

        let encryptedVaultKeyDataString = try Encryptor.encrypt(publicKey: config.publicKey,
                                                                clearData: verifiedContent,
                                                                signerKey: config.signerKey)
            .unArmor().value.base64EncodedString()

        return ItemKey(key: encryptedVaultKeyDataString,
                       keyRotation: key.keyRotation)
    }
}

private extension AcceptInvitation {
    func getConfig(invite: Invite,
                   addressKeys: [DecryptionKey],
                   userData: UserData) throws -> TransformKeyConfig {
        var config: TransformKeyConfig
        if case .user = invite {
            config = try getUserConfig(userData: userData)
        } else {
            guard let groupKey = addressKeys.first else {
                throw PassError.sharing(.invalidAddress(invite.invitedEmail))
            }
            let publicKey = ArmoredKey(value: groupKey.privateKey.armoredPublicKey)
            let signerKey = groupKey

            config = TransformKeyConfig(publicKey: publicKey, signerKey: signerKey)
        }
        return config
    }

    func getUserConfig(userData: UserData) throws -> TransformKeyConfig {
        guard let userKey = userData.user.keys.first else {
            throw PassError.crypto(.missingUserKey(userID: userData.user.ID))
        }

        guard let passphrase = userData.passphrases[userKey.keyID] else {
            throw PassError.crypto(.missingPassphrase(keyID: userKey.keyID))
        }

        let publicKey = ArmoredKey(value: userKey.publicKey)
        let privateKey = ArmoredKey(value: userKey.privateKey)
        let signerKey = SigningKey(privateKey: privateKey,
                                   passphrase: .init(value: passphrase))

        return TransformKeyConfig(publicKey: publicKey, signerKey: signerKey)
    }
}
