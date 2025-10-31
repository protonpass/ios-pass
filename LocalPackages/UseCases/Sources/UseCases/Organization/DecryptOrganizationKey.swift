//
//
// DecryptOrganizationKey.swift
// Proton Pass - Created on 29/09/2025.
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
//

import Client
import Core
@preconcurrency import CryptoKit
import Entities
import ProtonCoreCrypto
@preconcurrency import ProtonCoreLogin

public protocol DecryptOrganizationKeyUseCase: Sendable {
    func execute() async throws -> DecryptedOrgKey
}

public extension DecryptOrganizationKeyUseCase {
    func callAsFunction() async throws -> DecryptedOrgKey {
        try await execute()
    }
}

public struct DecryptedOrgKey {
    let privateKey: DecryptionKey
    let publicKey: String
}

public final class DecryptOrganizationKey: DecryptOrganizationKeyUseCase {
    private let userManager: any UserManagerProtocol
    private let repository: any OrganizationRepositoryProtocol

    public init(userManager: any UserManagerProtocol,
                repository: any OrganizationRepositoryProtocol) {
        self.userManager = userManager
        self.repository = repository
    }

    public func execute() async throws -> DecryptedOrgKey {
        guard let user = userManager.currentActiveUser.value else {
            throw PassError.noUserData
        }
        let organizationKey = try await repository.getOrganizationKeys(userId: user.user.ID)
        let orgToken = try getOrganizationKeyToken(userData: user, organizationKey: organizationKey)
        guard let privateKey = organizationKey.privateKey else {
            throw PassError.organizationNotFound
        }
        let armoredPrivateKey = ArmoredKey(value: privateKey)
        let decryptionKey = DecryptionKey(privateKey: armoredPrivateKey,
                                          passphrase: .init(value: orgToken))
        let publicKey = armoredPrivateKey.value.publicKey

        return DecryptedOrgKey(privateKey: decryptionKey, publicKey: publicKey)
    }
}

private extension DecryptOrganizationKey {
    func getOrganizationKeyToken(userData: UserData, organizationKey: OrganizationKey) throws -> String {
        guard organizationKey.isPasswordless else {
            return userData.credential.mailboxpassword
        }
        guard let token = organizationKey.token, let signature = organizationKey.signature else {
            throw PassError.crypto(.missingKeys)
        }
        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map(\.publicKey).map { ArmoredKey(value: $0) }

        let context = VerificationContext(value: Constants.organizationKeySignatureContext,
                                          required: .always)

        for decryptionKey in decryptionKeys {
            if let decryptedToken = try? Decryptor.decryptAndVerify(decryptionKey: decryptionKey,
                                                                    addrToken: ArmoredMessage(value: token),
                                                                    detachedSign: ArmoredSignature(value: signature),
                                                                    verificationKeys: verificationKeys,
                                                                    verificationContext: context) {
                return decryptedToken.content
            }
        }
        throw PassError.crypto(.missingKeys)
    }
}
