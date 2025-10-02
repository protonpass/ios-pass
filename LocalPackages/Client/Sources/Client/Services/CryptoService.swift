//
// CryptoService.swift
// Proton Pass - Created on 01/10/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import Entities
import Foundation
import ProtonCoreCrypto
@preconcurrency import ProtonCoreLogin

public protocol CryptoServiceProtocol: Sendable {
    func decryptShareKey(_ encryptedKey: ShareKey, userData: UserData, share: Share) async throws -> Data
}

public final class CryptoService: CryptoServiceProtocol {
//    private let shareRepository: any ShareRepositoryProtocol
    private let groupRepository: any GroupRepositoryProtocol
    private let logger: Logger
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let userManager: any UserManagerProtocol
    private let publicKeyRepository: any PublicKeyRepositoryProtocol

    public init(
//        shareRepository: any ShareRepositoryProtocol,
                groupRepository: any GroupRepositoryProtocol,
                logManager: any LogManagerProtocol,
                publicKeyRepository: any PublicKeyRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol) {
//        self.shareRepository = shareRepository
        self.groupRepository = groupRepository
        logger = .init(manager: logManager)
        self.publicKeyRepository = publicKeyRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.userManager = userManager
    }

    public func decryptShareKey(_ encryptedKey: ShareKey,
                                userData: UserData,
                                share: Share) async throws -> Data {
        let shareId = share.shareId
        let keyDescription = "shareId \"\(shareId)\", keyRotation: \"\(encryptedKey.keyRotation)\""

        guard let encryptedKeyData = try encryptedKey.key.base64Decode() else {
            logger.trace("Failed to base 64 decode share key \(keyDescription)")
            throw PassError.crypto(.failedToBase64Decode)
        }

        let armoredEncryptedKeyData = try CryptoUtils.armorMessage(encryptedKeyData)

//        // fetch share
//        guard let share = try await shareRepository.getShare(shareId: shareId) else {
//            throw PassError.itemsNotBelongToSameVault
//        }

        if let groupID = share.groupID {
            //  get address from user

            //            let address = userData.addresses.first { $0.addressID == share.addressId }

            guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: share.addressId,
                                                                     userData: userData).first else {
                throw PassError.crypto(.addressNotFound(addressID: share.addressId))
            }
            // get group loop to get group link to groupid

            guard let group = try await groupRepository.getGroups(userId: userData.user.ID)
                .first(where: { $0.id == groupID }),
                let groupAddressEmail = group.address?.email else {
                throw PassError.crypto(.missingGroupAddress)
            }
            let publickey = try await publicKeyRepository.getPublicKeys(email: groupAddressEmail)
            guard !publickey.isEmpty else {
                throw PassError.sharing(.noPublicKeyAssociatedWithEmail(groupAddressEmail))
            }
            let verificationKeys = publickey.map { ArmoredKey(value: $0.value) }

            let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: [addressKey],
                                                                            value: .init(value: armoredEncryptedKeyData),
                                                                            verificationKeys: verificationKeys)

            logger.trace("Decrypted share key \(keyDescription)")
            return decryptedKey.content
        } else {
            logger.trace("Decrypting share key \(keyDescription)")

            guard let userKey = userData.user.keys.first(where: { $0.keyID == encryptedKey.userKeyID }),
                  userKey.active == 1 else {
                throw PassError.crypto(.inactiveUserKey(userKeyId: encryptedKey.userKeyID))
            }

            let decryptionKeys = userData.user.keys.map {
                DecryptionKey(privateKey: .init(value: $0.privateKey),
                              passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
            }

            let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
            let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: decryptionKeys,
                                                                            value: .init(value: armoredEncryptedKeyData),
                                                                            verificationKeys: verificationKeys)

            logger.trace("Decrypted share key \(keyDescription)")
            return decryptedKey.content
        }

        //        if share.groupID == nil {
        //            logger.trace("Decrypting share key \(keyDescription)")
        //
        //            guard let userKey = userData.user.keys.first(where: { $0.keyID == encryptedKey.userKeyID }),
        //                  userKey.active == 1 else {
        //                throw PassError.crypto(.inactiveUserKey(userKeyId: encryptedKey.userKeyID))
        //            }
        //
        //            let decryptionKeys = userData.user.keys.map {
        //                DecryptionKey(privateKey: .init(value: $0.privateKey),
        //                              passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        //            }
        //
        //            let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
        //            let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys:
        //            decryptionKeys,
        //                                                                            value: .init(value: armoredEncryptedKeyData),
        //                                                                            verificationKeys: verificationKeys)
        //
        //            logger.trace("Decrypted share key \(keyDescription)")
        //            return decryptedKey.content
        //        } else {
        //            guard  let groupID = share.groupID else {
        //                throw PassError.crypto(.missingGroupId)
        //            }
        //          //  get address from user
        //
        ////            let address = userData.addresses.first { $0.addressID == share.addressId }
        //
        //            guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: share.addressId,
        //                                                                     userData: userData).first else {
        //                throw PassError.crypto(.addressNotFound(addressID: share.addressId))
        //            }
        //            // get group loop to get group link to groupid
        //
        //            let group = //fetch and loop
        //
        //            let groupAddressEmail = // get the email of optionnal address of group
        //
        //            let publickey = // get public keys of groupAddressEmail
        //
        //            let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: [addressKey],
        //                                                                            value: .init(value: armoredEncryptedKeyData),
        //                                                                            verificationKeys: publickey)
        //
        //            logger.trace("Decrypted share key \(keyDescription)")
        //            return decryptedKey.content
        //        }
    }
}

// private let localDatasource: any LocalShareKeyDatasourceProtocol
// private let remoteDatasource: any RemoteShareKeyDatasourceProtocol
// private let shareRepository: any ShareRepositoryProtocol
// private let groupRepository: any GroupRepositoryProtocol
// private let logger: Logger
// private let symmetricKeyProvider: any SymmetricKeyProvider
// private let getEmailPublicKeyUseCase: any GetEmailPublicKeyUseCase
//
// public init(localDatasource: any LocalShareKeyDatasourceProtocol,
//            remoteDatasource: any RemoteShareKeyDatasourceProtocol,
//            shareRepository: any ShareRepositoryProtocol,
//            groupRepository: any GroupRepositoryProtocol,
//            logManager: any LogManagerProtocol,
//            getEmailPublicKeyUseCase: any GetEmailPublicKeyUseCase,
//            symmetricKeyProvider: any SymmetricKeyProvider,
//            userManager: any UserManagerProtocol) {
//    self.localDatasource = localDatasource
//    self.remoteDatasource = remoteDatasource
//    self.shareRepository = shareRepository
//    self.groupRepository = groupRepository
//    logger = .init(manager: logManager)
//    self.symmetricKeyProvider = symmetricKeyProvider
//    self.userManager = userManager
// }
//
// public final class GetEmailPublicKey: @unchecked Sendable, GetEmailPublicKeyUseCase {
//
//    public init(publicKeyRepository: any PublicKeyRepositoryProtocol) {
//        self.publicKeyRepository = publicKeyRepository
//    }
//
//    public func execute(with email: String) async throws -> [PublicKey] {
//        do {
//            let keys = try await publicKeyRepository.getPublicKeys(email: email)
//            guard !keys.isEmpty else {
//                throw PassError.sharing(.noPublicKeyAssociatedWithEmail(email))
//            }
//            return keys
//        } catch {
//            if let networkError = error as? ProtonCoreNetworking.ResponseError,
//               networkError.httpCode == 422,
//               [33_102, 33_103].contains(networkError.responseCode) {
//                throw PassError.sharing(.notProtonAddress)
//            } else {
//                throw error
//            }
//        }
//    }
// }

//
//
//
// func getSymmetricKey() async throws -> CryptoKit.SymmetricKey {
//    try await symmetricKeyProvider.getSymmetricKey()
// }
//
////TODO: add logic for group shares
// func decrypt(_ encryptedKey: ShareKey, userData: UserData, shareId: String) async throws -> Data {
//    let keyDescription = "shareId \"\(shareId)\", keyRotation: \"\(encryptedKey.keyRotation)\""
//
//    guard let encryptedKeyData = try encryptedKey.key.base64Decode() else {
//        logger.trace("Failed to base 64 decode share key \(keyDescription)")
//        throw PassError.crypto(.failedToBase64Decode)
//    }
//
//    let armoredEncryptedKeyData = try CryptoUtils.armorMessage(encryptedKeyData)
//
//    // fetch share
//    guard let share = try await shareRepository.getShare(shareId: shareId) else {
//        throw PassError.itemsNotBelongToSameVault
//    }
//
//    if let groupID = share.groupID {
//        //  get address from user
//
////            let address = userData.addresses.first { $0.addressID == share.addressId }
//
//          guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: share.addressId,
//                                                                   userData: userData).first else {
//              throw PassError.crypto(.addressNotFound(addressID: share.addressId))
//          }
//          // get group loop to get group link to groupid
//
//        guard let group = try await groupRepository.getGroups(userId: userData.user.ID).first(where: { $0.id ==
//        groupID}),
//              let groupAddressEmail = group.address?.email else {
//
//        }
//
//
//          let publickey = // get public keys of groupAddressEmail
//
//          let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: [addressKey],
//                                                                          value: .init(value: armoredEncryptedKeyData),
//                                                                          verificationKeys: publickey)
//
//          logger.trace("Decrypted share key \(keyDescription)")
//          return decryptedKey.content
//    } else {
//        logger.trace("Decrypting share key \(keyDescription)")
//
//        guard let userKey = userData.user.keys.first(where: { $0.keyID == encryptedKey.userKeyID }),
//              userKey.active == 1 else {
//            throw PassError.crypto(.inactiveUserKey(userKeyId: encryptedKey.userKeyID))
//        }
//
//        let decryptionKeys = userData.user.keys.map {
//            DecryptionKey(privateKey: .init(value: $0.privateKey),
//                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
//        }
//
//        let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
//        let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: decryptionKeys,
//                                                                        value: .init(value: armoredEncryptedKeyData),
//                                                                        verificationKeys: verificationKeys)
//
//        logger.trace("Decrypted share key \(keyDescription)")
//        return decryptedKey.content
//    }
//
//
//
//
////        if share.groupID == nil {
////            logger.trace("Decrypting share key \(keyDescription)")
////
////            guard let userKey = userData.user.keys.first(where: { $0.keyID == encryptedKey.userKeyID }),
////                  userKey.active == 1 else {
////                throw PassError.crypto(.inactiveUserKey(userKeyId: encryptedKey.userKeyID))
////            }
////
////            let decryptionKeys = userData.user.keys.map {
////                DecryptionKey(privateKey: .init(value: $0.privateKey),
////                              passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
////            }
////
////            let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
////            let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: decryptionKeys,
////                                                                            value: .init(value:
/// armoredEncryptedKeyData),
////                                                                            verificationKeys: verificationKeys)
////
////            logger.trace("Decrypted share key \(keyDescription)")
////            return decryptedKey.content
////        } else {
////            guard  let groupID = share.groupID else {
////                throw PassError.crypto(.missingGroupId)
////            }
////          //  get address from user
////
//////            let address = userData.addresses.first { $0.addressID == share.addressId }
////
////            guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: share.addressId,
////                                                                     userData: userData).first else {
////                throw PassError.crypto(.addressNotFound(addressID: share.addressId))
////            }
////            // get group loop to get group link to groupid
////
////            let group = //fetch and loop
////
////            let groupAddressEmail = // get the email of optionnal address of group
////
////            let publickey = // get public keys of groupAddressEmail
////
////            let decryptedKey: VerifiedData = try Decryptor.decryptAndVerify(decryptionKeys: [addressKey],
////                                                                            value: .init(value:
/// armoredEncryptedKeyData),
////                                                                            verificationKeys: publickey)
////
////            logger.trace("Decrypted share key \(keyDescription)")
////            return decryptedKey.content
////        }
// }
