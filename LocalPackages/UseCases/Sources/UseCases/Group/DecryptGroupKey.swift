//
// DecryptGroupKey.swift
// Proton Pass - Created on 03/10/2025.
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

@preconcurrency import CryptoKit
import Entities
import ProtonCoreCrypto
@preconcurrency import ProtonCoreLogin

public protocol DecryptGroupKeyUseCase: Sendable {
    func execute(group: Group, isGroupOwner: Bool, userData: UserData) async throws -> DecryptedGroupAddressKey
}

public extension DecryptGroupKeyUseCase {
    func callAsFunction(group: Group,
                        isGroupOwner: Bool,
                        userData: UserData) async throws -> DecryptedGroupAddressKey {
        try await execute(group: group, isGroupOwner: isGroupOwner, userData: userData)
    }
}

public struct DecryptedGroupAddressKey {
    let privateKey: DecryptionKey
    let publicKey: String
    let groupAddressKey: GroupAddressKey
}

public final class DecryptGroupKey: DecryptGroupKeyUseCase {
    private let decryptOrganizationKey: any DecryptOrganizationKeyUseCase

    public init(decryptOrganizationKey: any DecryptOrganizationKeyUseCase) {
        self.decryptOrganizationKey = decryptOrganizationKey
    }

    public func execute(group: Group,
                        isGroupOwner: Bool,
                        userData: UserData) async throws -> DecryptedGroupAddressKey {
        guard let address = group.address,
              let primaryKey = address.keys.first(where: { $0.primary == 1 })
        else {
            throw PassError.crypto(.missingGroupAddress(group.id))
        }

        let content = if isGroupOwner {
            try decryptWithUserKeys(primaryKey: primaryKey, userData: userData)
        } else {
            try await decryptWithOrgKeys(primaryKey: primaryKey, userData: userData)
        }

        let armoredPrivateKey = ArmoredKey(value: primaryKey.privateKey)
        let privateKey = DecryptionKey(privateKey: armoredPrivateKey,
                                       passphrase: .init(value: content))
        let publicKey = armoredPrivateKey.value.publicKey

        return DecryptedGroupAddressKey(privateKey: privateKey, publicKey: publicKey, groupAddressKey: primaryKey)
    }
}

private extension DecryptGroupKey {
    func decryptWithOrgKeys(primaryKey: GroupAddressKey, userData: UserData) async throws -> String {
        let orgKey = try await decryptOrganizationKey(user: userData)

        let decryptedToken = try Decryptor.decryptAndVerify(decryptionKey: orgKey.privateKey,
                                                            addrToken: ArmoredMessage(value: primaryKey.token),
                                                            detachedSign: ArmoredSignature(value: primaryKey
                                                                .signature),
                                                            verificationKeys: [orgKey.privateKey.privateKey])

        guard case let .verified(content) = decryptedToken else {
            throw PassError.crypto(.failedToVerifySignature)
        }

        return content
    }

    func decryptWithUserKeys(primaryKey: GroupAddressKey, userData: UserData) throws -> String {
        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }
        let context = VerificationContext(value: "account.key-token.address", required: .always)
        for decryptionKey in decryptionKeys {
            if let decryptedToken = try? Decryptor.decryptAndVerify(decryptionKey: decryptionKey,
                                                                    addrToken: ArmoredMessage(value: primaryKey
                                                                        .token),
                                                                    detachedSign: ArmoredSignature(value: primaryKey
                                                                        .signature),
                                                                    verificationKeys: verificationKeys,
                                                                    verificationContext: context) {
                return try decryptedToken.verifiedContent
            }
        }
        throw PassError.crypto(.missingKeys)
    }
}
