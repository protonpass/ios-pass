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
import ProtonCoreNetworking
import UseCases

@preconcurrency import ProtonCoreLogin

protocol AcceptInvitationUseCase: Sendable {
    func execute(with userInvite: UserInvite) async throws -> Bool
}

extension AcceptInvitationUseCase {
    func callAsFunction(with userInvite: UserInvite) async throws -> Bool {
        try await execute(with: userInvite)
    }
}

final class AcceptInvitation: AcceptInvitationUseCase {
    private let repository: InviteRepositoryProtocol
    private let userDataProvider: UserDataProvider
    private let getEmailPublicKey: GetEmailPublicKeyUseCase
    private let updateUserAddresses: UpdateUserAddressesUseCase

    init(repository: InviteRepositoryProtocol,
         userDataProvider: UserDataProvider,
         getEmailPublicKey: GetEmailPublicKeyUseCase,
         updateUserAddresses: UpdateUserAddressesUseCase) {
        self.repository = repository
        self.userDataProvider = userDataProvider
        self.getEmailPublicKey = getEmailPublicKey
        self.updateUserAddresses = updateUserAddresses
    }

    func execute(with userInvite: UserInvite) async throws -> Bool {
        let encrytedKeys = try await encryptKeys(userInvite: userInvite)
        return try await repository.acceptInvite(with: userInvite.inviteToken, and: encrytedKeys)
    }
}

private extension AcceptInvitation {
    func encryptKeys(userInvite: UserInvite) async throws -> [ItemKey] {
        let userData = try userDataProvider.getUnwrappedUserData()
        guard let address = try await fetchInvitedAddress(with: userInvite, userData: userData) else {
            throw PassError.sharing(.invalidKeyOrAddress)
        }
        let addressKeys = try CryptoUtils.unlockAddressKeys(address: address,
                                                            userData: userData)
        let inviterPublicKeys = try await getEmailPublicKey(with: userInvite.inviterEmail)
        let armoredInviterPublicKeys = inviterPublicKeys.map { ArmoredKey(value: $0.value) }

        let reencrytedKeys: [ItemKey] = try userInvite.keys.map { key in
            try transformKey(key: key,
                             addressKeys: addressKeys,
                             armoredInviterPublicKeys: armoredInviterPublicKeys,
                             userData: userData)
        }
        return reencrytedKeys
    }

    func transformKey(key: ItemKey,
                      addressKeys: [DecryptionKey],
                      armoredInviterPublicKeys: [ArmoredKey],
                      userData: UserData) throws -> ItemKey {
        guard let decodeKey = try? key.key.base64Decode() else {
            throw PassError.sharing(.cannotDecode)
        }

        let armoredEncryptedKeyData = try CryptoUtils.armorMessage(decodeKey)
        let armorMessage = ArmoredMessage(value: armoredEncryptedKeyData)
        let context = VerificationContext(value: Constants.existingUserSharingSignatureContext,
                                          required: .always)

        let decode: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: addressKeys,
                                                                  value: armorMessage,
                                                                  verificationKeys: armoredInviterPublicKeys,
                                                                  verificationContext: context)

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

        let encryptedVaultKeyDataString = try Encryptor.encrypt(publicKey: publicKey,
                                                                clearData: decode.content,
                                                                signerKey: signerKey)
            .unArmor().value.base64EncodedString()

        return ItemKey(key: encryptedVaultKeyDataString,
                       keyRotation: key.keyRotation)
    }
}

private extension AcceptInvitation {
    func fetchInvitedAddress(with userInvite: UserInvite, userData: UserData) async throws -> Address? {
        guard let invitedAddress = userData.address(for: userInvite.invitedEmail) else {
            return try await updateUserAddresses()?
                .first(where: { $0.email == userInvite.invitedEmail })
        }
        return invitedAddress
    }
}
