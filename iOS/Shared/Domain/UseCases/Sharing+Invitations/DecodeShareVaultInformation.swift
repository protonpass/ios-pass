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
import UseCases

protocol DecodeShareVaultInformationUseCase: Sendable {
    func execute(with userInvite: UserInvite) async throws -> VaultProtobuf
}

extension DecodeShareVaultInformationUseCase {
    func callAsFunction(with userInvite: UserInvite) async throws -> VaultProtobuf {
        try await execute(with: userInvite)
    }
}

final class DecodeShareVaultInformation: @unchecked Sendable, DecodeShareVaultInformationUseCase {
    private let userDataProvider: UserDataProvider
    private let getEmailPublicKey: GetEmailPublicKeyUseCase
    private let updateUserAddresses: UpdateUserAddressesUseCase

    init(userDataProvider: UserDataProvider,
         getEmailPublicKey: GetEmailPublicKeyUseCase,
         updateUserAddresses: UpdateUserAddressesUseCase) {
        self.userDataProvider = userDataProvider
        self.getEmailPublicKey = getEmailPublicKey
        self.updateUserAddresses = updateUserAddresses
    }

    func execute(with userInvite: UserInvite) async throws -> VaultProtobuf {
        let userData = try userDataProvider.getUnwrappedUserData()
        guard let vaultData = userInvite.vaultData,
              let intermediateVaultKey = userInvite.keys
              .first(where: { $0.keyRotation == vaultData.contentKeyRotation }),
              let invitedAddress = try await address(for: userInvite, userData: userData) else {
            throw PassError.sharing(.invalidKeyOrAddress)
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

        guard let content = try vaultData.content.base64Decode() else {
            throw PassError.sharing(.cannotDecode)
        }

        let decryptedContent = try AES.GCM.open(content,
                                                key: decode.content,
                                                associatedData: .vaultContent)
        let vaultContent = try VaultProtobuf(data: decryptedContent)

        return vaultContent
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
