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
    func execute(with userInvite: UserInvite) async throws -> VaultContent
}

public extension DecodeShareVaultInformationUseCase {
    func callAsFunction(with userInvite: UserInvite) async throws -> VaultContent {
        try await execute(with: userInvite)
    }
}

public final class DecodeShareVaultInformation: @unchecked Sendable, DecodeShareVaultInformationUseCase {
    private let userManager: any UserManagerProtocol
    private let getEmailPublicKey: any GetEmailPublicKeyUseCase
    private let updateUserAddresses: any UpdateUserAddressesUseCase
    private let logger: Logger

    public init(userManager: any UserManagerProtocol,
                getEmailPublicKey: any GetEmailPublicKeyUseCase,
                updateUserAddresses: any UpdateUserAddressesUseCase,
                logManager: any LogManagerProtocol) {
        self.userManager = userManager
        self.getEmailPublicKey = getEmailPublicKey
        self.updateUserAddresses = updateUserAddresses
        logger = .init(manager: logManager)
    }

    public func execute(with userInvite: UserInvite) async throws -> VaultContent {
        logger.trace("Start decoding invitation share information for invitee user \(userInvite.invitedEmail)")

        do {
            let userData = try await userManager.getUnwrappedActiveUserData()
            guard let vaultData = userInvite.vaultData,
                  let intermediateVaultKey = userInvite.keys
                  .first(where: { $0.keyRotation == vaultData.contentKeyRotation }) else {
                throw PassError.sharing(.invalidKey)
            }
            guard let invitedAddress = try await address(for: userInvite, userData: userData) else {
                throw PassError.sharing(.invalidAddress(userInvite.invitedEmail))
            }

            let invitedAddressKeys = try CryptoUtils.unlockAddressKeys(address: invitedAddress,
                                                                       userData: userData)

            guard let decodedIntermediateVaultKey = try intermediateVaultKey.key.base64Decode() else {
                throw PassError.sharing(.cannotDecode)
            }

            let inviterPublicKeys = try await getEmailPublicKey(with: userInvite.inviterEmail)
            let armoredEncryptedVaultKeyData = try CryptoUtils.armorMessage(decodedIntermediateVaultKey)

            let vaultKeyArmorMessage = ArmoredMessage(value: armoredEncryptedVaultKeyData)
            let armoredInviterPublicKeys = inviterPublicKeys.map { ArmoredKey(value: $0.value) }
            let context = VerificationContext(value: Constants.existingUserSharingSignatureContext,
                                              required: .always)

            let decode: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: invitedAddressKeys,
                                                                      value: vaultKeyArmorMessage,
                                                                      verificationKeys: armoredInviterPublicKeys,
                                                                      verificationContext: context)
            let verifiedContent = try decode.verifiedContent

            guard let content = try vaultData.content.base64Decode() else {
                throw PassError.sharing(.cannotDecode)
            }

            let decryptedContent = try AES.GCM.open(content,
                                                    key: verifiedContent,
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
    func address(for userInvite: UserInvite, userData: UserData) async throws -> Address? {
        guard let invitedAddress = userData.address(for: userInvite.invitedEmail) else {
            return try await updateUserAddresses()?
                .first(where: { $0.email == userInvite.invitedEmail })
        }
        return invitedAddress
    }
}
