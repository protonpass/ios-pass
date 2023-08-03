//
// UpdateCredentialRank.swift
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

import AuthenticationServices
import Client
import Core

/// Update the rank of an `ASPasswordCredentialIdentity` object that corresponds to a login item in the credential
/// database so that it'll be shown at the top of the suggested items for a given domain.
/// We don't manipulate directly an instance of `ASPasswordCredentialIdentity` but a proxy `AutoFillCredential`
protocol UpdateCredentialRankUseCase: Sendable {
    func execute(itemContent: ItemContent,
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 lastUseTime: TimeInterval) async throws
}

extension UpdateCredentialRankUseCase {
    func callAsFunction(itemContent: ItemContent,
                        serviceIdentifiers: [ASCredentialServiceIdentifier],
                        lastUseTime: TimeInterval) async throws {
        try await execute(itemContent: itemContent,
                          serviceIdentifiers: serviceIdentifiers,
                          lastUseTime: lastUseTime)
    }
}

final class UpdateCredentialRank: @unchecked Sendable, UpdateCredentialRankUseCase {
    private let credentialManager: CredentialManagerProtocol
    private let logger: Logger

    init(credentialManager: CredentialManagerProtocol,
         logManager: LogManagerProtocol) {
        self.credentialManager = credentialManager
        logger = .init(manager: logManager)
    }

    func execute(itemContent: ItemContent,
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 lastUseTime: TimeInterval) async throws {
        guard case let .login(data) = itemContent.contentData else {
            let error = PPError.credentialProvider(.notLogInItem)
            logger.error(error)
            throw error
        }

        let itemUrls = data.urls.compactMap { URL(string: $0) }

        let serviceUrls = serviceIdentifiers
            .map { serviceIdentifier in
                switch serviceIdentifier.type {
                case .URL:
                    return serviceIdentifier.identifier
                case .domain:
                    return "https://\(serviceIdentifier.identifier)"
                @unknown default:
                    return serviceIdentifier.identifier
                }
            }
            .compactMap { URL(string: $0) }

        let matchedUrls = itemUrls.filter { itemUrl in
            serviceUrls.contains { serviceUrl in
                if case .matched = URLUtils.Matcher.compare(itemUrl, serviceUrl) {
                    return true
                }
                return false
            }
        }

        let credentials = matchedUrls
            .map { AutoFillCredential(shareId: itemContent.shareId,
                                      itemId: itemContent.itemId,
                                      username: data.username,
                                      url: $0.absoluteString,
                                      lastUseTime: Int64(lastUseTime)) }

        logger.trace("Updating rank \(itemContent.debugInformation)")
        try await credentialManager.insert(credentials: credentials)
        logger.info("Updated rank \(itemContent.debugInformation)")
    }
}
