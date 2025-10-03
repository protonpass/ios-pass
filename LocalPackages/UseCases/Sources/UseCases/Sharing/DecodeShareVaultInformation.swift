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
    func execute(with invite: InviteType) async throws -> VaultContent
}

public extension DecodeShareVaultInformationUseCase {
    func callAsFunction(with invite: InviteType) async throws -> VaultContent {
        try await execute(with: invite)
    }
}

public final class DecodeShareVaultInformation: @unchecked Sendable, DecodeShareVaultInformationUseCase {
    private let userManager: any UserManagerProtocol
    private let getEmailPublicKey: any GetEmailPublicKeyUseCase
    private let updateUserAddresses: any UpdateUserAddressesUseCase
    private let groupRepository: any GroupRepositoryProtocol
    private let decryptGroupKeys: any DecryptGroupKeyUseCase
    private let logger: Logger

    public init(userManager: any UserManagerProtocol,
                getEmailPublicKey: any GetEmailPublicKeyUseCase,
                updateUserAddresses: any UpdateUserAddressesUseCase,
                decryptGroupKeys: any DecryptGroupKeyUseCase,
                groupRepository: any GroupRepositoryProtocol,
                logManager: any LogManagerProtocol) {
        self.userManager = userManager
        self.getEmailPublicKey = getEmailPublicKey
        self.updateUserAddresses = updateUserAddresses
        self.groupRepository = groupRepository
        self.decryptGroupKeys = decryptGroupKeys
        logger = .init(manager: logManager)
    }

    // TODO: add group sharing logic
    public func execute(with invite: InviteType) async throws -> VaultContent {
        logger.trace("Start decoding invitation share information for invitee user \(invite.invitedEmail)")

        do {
            let userData = try await userManager.getUnwrappedActiveUserData()
            guard let vaultData = invite.vaultData,
                  let intermediateVaultKey = invite.keys
                  .first(where: { $0.keyRotation == vaultData.contentKeyRotation }) else {
                throw PassError.sharing(.invalidKey)
            }

            guard let encryptedVaultContent = try vaultData.content.base64Decode() else {
                throw PassError.sharing(.cannotDecode)
            }

            let encryptedValue = try getValue(intermediateVaultKey: intermediateVaultKey)
            let decryptionKeys = try await getDecryptionKeys(invite: invite, userData: userData)
            let verificationsKeys = try await getVerificationKeys(invite: invite)

            let context = VerificationContext(value: Constants.existingUserSharingSignatureContext,
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
    func getDecryptionKeys(invite: InviteType, userData: UserData) async throws -> [DecryptionKey] {
        switch invite {
        case let .user(invite):
            guard let invitedAddress = try await address(for: invite, userData: userData) else {
                throw PassError.sharing(.invalidAddress(invite.invitedEmail))
            }

            return try CryptoUtils.unlockAddressKeys(address: invitedAddress,
                                                     userData: userData)
        case let .group(invite):
            guard let group = try await groupRepository.getGroups(userId: userData.user.ID)
                .first(where: { $0.id == invite.invitedGroupID }) else {
                throw PassError.crypto(.missingGroupAddress)
            }
            let groupAddressKeys = try await decryptGroupKeys(group: group)
            return [groupAddressKeys.privateKey]
        }
    }

    func getVerificationKeys(invite: InviteType) async throws -> [ArmoredKey] {
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

//    func decryptUserInvite(invite: UserInvite, userData: UserData) async throws -> VaultContent {
    ////        guard let vaultData = invite.vaultData,
    ////              let intermediateVaultKey = invite.keys
    ////              .first(where: { $0.keyRotation == vaultData.contentKeyRotation }) else {
    ////            throw PassError.sharing(.invalidKey)
    ////        }
//        guard let invitedAddress = try await address(for: invite, userData: userData) else {
//            throw PassError.sharing(.invalidAddress(invite.invitedEmail))
//        }
//
//        let invitedAddressKeys = try CryptoUtils.unlockAddressKeys(address: invitedAddress,
//                                                                   userData: userData)
//
//        guard let decodedIntermediateVaultKey = try intermediateVaultKey.key.base64Decode() else {
//            throw PassError.sharing(.cannotDecode)
//        }
//
//        let inviterPublicKeys = try await getEmailPublicKey(with: invite.inviterEmail)
//        let armoredEncryptedVaultKeyData = try CryptoUtils.armorMessage(decodedIntermediateVaultKey)
//
//        let vaultKeyArmorMessage = ArmoredMessage(value: armoredEncryptedVaultKeyData)
//        let armoredInviterPublicKeys = inviterPublicKeys.map { ArmoredKey(value: $0.value) }
//        let context = VerificationContext(value: Constants.existingUserSharingSignatureContext,
//                                          required: .always)
//
//        let decode: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: invitedAddressKeys,
//                                                                  value: vaultKeyArmorMessage,
//                                                                  verificationKeys: armoredInviterPublicKeys,
//                                                                  verificationContext: context)
//
//        guard let content = try vaultData.content.base64Decode() else {
//            throw PassError.sharing(.cannotDecode)
//        }
//
//        let decryptedContent = try AES.GCM.open(content,
//                                                key: decode.content,
//                                                associatedData: .vaultContent)
//        let vaultContent = try VaultContent(data: decryptedContent)
//        logger.trace("Finished decoding vault content")
//        return vaultContent
//    }

    func address(for userInvite: UserInvite, userData: UserData) async throws -> Address? {
        guard let invitedAddress = userData.address(for: userInvite.invitedEmail) else {
            return try await updateUserAddresses()?
                .first(where: { $0.email == userInvite.invitedEmail })
        }
        return invitedAddress
    }

//    func decryptGroupInvite(invite: GroupInvite) async throws -> VaultContent {
//
//    }
//    func address(for invite: InviteType, userData: UserData) async throws -> Address? {
//
    ////        switch invite {
    ////        case let .user(invite):
    ////            guard let invitedAddress = userData.address(for: invite.invitedEmail) else {
    ////                return try await updateUserAddresses()?
    ////                    .first(where: { $0.email == invite.invitedEmail })
    ////            }
    ////            return invitedAddress
    ////        case let .group(invite):
    ////            return nil
    //////            let groups = try await groupRepository.getGroups(userId: userData.user.ID)
    //////            return groups.compactMap { $0.address }.first(where: { $0.email.lowercased() ==
    //////            invite.invitedEmail.lowercased() })
    ////        }
//    }

//    func groupAddress(for invite: InviteType, group: Group) async throws -> Address? {
//        group.address.first(where: { $0.email.lowercased() == invite.invitedEmail.lowercased() })
//
//    }
}

// extension GroupAddress {
//    var toAddress: Address {
//        Address(addressID: <#T##String#>,
//                domainID: <#T##String?#>,
//                email: <#T##String#>,
//                send: <#T##Address.AddressSendReceive#>, receive: <#T##Address.AddressSendReceive#>, status: <#T##Address.AddressStatus#>, type: <#T##Address.AddressType#>, order: <#T##Int#>, displayName: <#T##String#>, signature: <#T##String#>, hasKeys: <#T##Int#>, keys: <#T##[Key]#>)
//    }
// }

//
// async readGroupVaultInvite({
//    inviteKey,
//    organizationKey,
//    groupKeys,
//    encryptedVaultContent,
//    inviterPublicKeys,
// }) {
//    assertHydrated(context);
//
//    const decryptedGroupKey = await getDecryptedGroupKey(organizationKey, groupKeys);
//
//    return processes.readVaultInviteContent({
//        inviteKey,
//        encryptedVaultContent,
//        invitedPrivateKey: decryptedGroupKey!.privateKey,
//        inviterPublicKeys: await Promise.all(
//            inviterPublicKeys.map((armoredKey) => CryptoProxy.importPublicKey({ armoredKey }))
//        ),
//    });
// },
