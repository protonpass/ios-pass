//
//
// RecreateSecureLink.swift
// Proton Pass - Created on 13/06/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import CryptoKit
import Entities

public protocol RecreateSecureLinkUseCase: Sendable {
    func execute(for link: SecureLink) async throws -> String
}

public extension RecreateSecureLinkUseCase {
    func callAsFunction(for link: SecureLink) async throws -> String {
        try await execute(for: link)
    }
}

public final class RecreateSecureLink: RecreateSecureLinkUseCase {
    private let passKeyManager: any PassKeyManagerProtocol

    public init(passKeyManager: any PassKeyManagerProtocol) {
        self.passKeyManager = passKeyManager
    }

    public func execute(for link: SecureLink) async throws -> String {
        let shareKey = try await passKeyManager.getShareKey(shareId: link.shareID,
                                                            keyRotation: link
                                                                .linkKeyShareKeyRotation)

        guard let linkKeyData = try link.encryptedLinkKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedLinkKeyData = try AES.GCM.open(linkKeyData,
                                                    key: shareKey.keyData,
                                                    associatedData: .linkKey)

        return "\(link.linkURL)#\(decryptedLinkKeyData.base64URLSafeEncodedString())"
    }
}
