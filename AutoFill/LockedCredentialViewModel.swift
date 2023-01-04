//
// LockedCredentialViewModel.swift
// Proton Pass - Created on 25/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import AuthenticationServices
import Client
import Core
import CryptoKit
import SwiftUI

final class LockedCredentialViewModel: ObservableObject {
    private let itemRepository: ItemRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private let credentialIdentity: ASPasswordCredentialIdentity
    private let logger: Logger
    let logManager: LogManager

    var onFailure: ((Error) -> Void)?
    var onSuccess: ((ASPasswordCredential, SymmetricallyEncryptedItem) -> Void)?

    init(itemRepository: ItemRepositoryProtocol,
         symmetricKey: SymmetricKey,
         credentialIdentity: ASPasswordCredentialIdentity,
         logManager: LogManager) {
        self.itemRepository = itemRepository
        self.symmetricKey = symmetricKey
        self.credentialIdentity = credentialIdentity
        self.logManager = logManager
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    func getAndReturnCredential() {
        Task {
            do {
                guard let recordIdentifier = credentialIdentity.recordIdentifier else {
                    throw CredentialProviderError.emptyRecordIdentifier
                }
                let ids = try AutoFillCredential.IDs.deserializeBase64(recordIdentifier)
                logger.trace("Loading credential \(ids.debugInformation)")
                guard let item = try await self.itemRepository.getItem(shareId: ids.shareId,
                                                                       itemId: ids.itemId) else {
                    throw CredentialsViewModelError.itemNotFound(shareId: ids.shareId,
                                                                 itemId: ids.itemId)
                }
                let itemContent = try item.getDecryptedItemContent(symmetricKey: self.symmetricKey)

                switch itemContent.contentData {
                case let .login(username, password, _):
                    let credential = ASPasswordCredential(user: username, password: password)
                    onSuccess?(credential, item)
                    logger.info("Loaded and returned credential \(ids.debugInformation)")
                default:
                    throw CredentialsViewModelError.notLogInItem
                }
            } catch {
                logger.error(error)
                onFailure?(error)
            }
        }
    }

    func handleAuthenticationFailure() {
        onFailure?(CredentialProviderError.failedToAuthenticate)
    }

    func handleCancellation() {
        onFailure?(CredentialProviderError.userCancelled)
    }
}
