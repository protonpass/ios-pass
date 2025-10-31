//
//
// DecodeShareVaultInformation.swift
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
import CryptoKit
import Entities
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreLogin

public protocol DecodeShareVaultInformationUseCase: Sendable {
    func execute(with invite: Invite) async throws -> VaultContent
}

public extension DecodeShareVaultInformationUseCase {
    func callAsFunction(with invite: Invite) async throws -> VaultContent {
        try await execute(with: invite)
    }
}

public final class DecodeShareVaultInformation: @unchecked Sendable, DecodeShareVaultInformationUseCase {
    private let getEmailPublicKey: any GetEmailPublicKeyUseCase
    private let getInviteDecryptionKeys: any GetInviteDecryptionKeysUseCase
    private let logger: Logger

    public init(getEmailPublicKey: any GetEmailPublicKeyUseCase,
                getInviteDecryptionKeys: GetInviteDecryptionKeysUseCase,
                logManager: any LogManagerProtocol) {
        self.getEmailPublicKey = getEmailPublicKey
        self.getInviteDecryptionKeys = getInviteDecryptionKeys
        logger = .init(manager: logManager)
    }

    public func execute(with invite: Invite) async throws -> VaultContent {
        logger.trace("Start decoding invitation share information for invitee user \(invite.invitedEmail)")

        do {
            guard let vaultData = invite.vaultData,
                  let intermediateVaultKey = invite.keys
                  .first(where: { $0.keyRotation == vaultData.contentKeyRotation }) else {
                throw PassError.sharing(.invalidKey)
            }

            guard let encryptedVaultContent = try vaultData.content.base64Decode() else {
                throw PassError.sharing(.cannotDecode)
            }

            let encryptedValue = try getValue(intermediateVaultKey: intermediateVaultKey)

            async let decryptionKeysProcess = try getInviteDecryptionKeys(invite: invite)
            async let verificationsKeysProcess = try getVerificationKeys(invite: invite)

            let (decryptionKeys, verificationsKeys) = try await (decryptionKeysProcess, verificationsKeysProcess)

            let context = VerificationContext(value: Constants.SignatureContext.existingUserSharing,
                                              required: .always)

            let decode: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: decryptionKeys,
                                                                      value: encryptedValue,
                                                                      verificationKeys: verificationsKeys,
                                                                      verificationContext: context)

            let decryptedContent = try AES.GCM.open(encryptedVaultContent,
                                                    key: decode.content,
                                                    associatedData: .vaultContent)
            let vaultContent = try VaultContent(data: decryptedContent)
            logger.trace("Finished decoding vault content")
            return vaultContent
        } catch {
            logger.error(error)
            throw error
        }
    }
}

private extension DecodeShareVaultInformation {
    func getVerificationKeys(invite: Invite) async throws -> [ArmoredKey] {
        let inviterPublicKeys = try await getEmailPublicKey(with: invite.inviterEmail)
        return inviterPublicKeys.map { ArmoredKey(value: $0.value) }
    }

    func getValue(intermediateVaultKey: ItemKey) throws -> ArmoredMessage {
        guard let decodedIntermediateVaultKey = try intermediateVaultKey.key.base64Decode() else {
            throw PassError.sharing(.cannotDecode)
        }

        let armoredEncryptedVaultKeyData = try CryptoUtils.armorMessage(decodedIntermediateVaultKey)

        return ArmoredMessage(value: armoredEncryptedVaultKeyData)
    }
}
