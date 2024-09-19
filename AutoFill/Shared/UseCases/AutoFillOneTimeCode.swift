//
// AutoFillOneTimeCode.swift
// Proton Pass - Created on 19/09/2024.
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

import AuthenticationServices
import Client
import Entities

protocol AutoFillOneTimeCodeUseCase: Sendable {
    func execute(_ item: any ItemIdentifiable,
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 context: ASCredentialProviderExtensionContext) async throws
}

extension AutoFillOneTimeCodeUseCase {
    func callAsFunction(_ item: any ItemIdentifiable,
                        serviceIdentifiers: [ASCredentialServiceIdentifier],
                        context: ASCredentialProviderExtensionContext) async throws {
        try await execute(item, serviceIdentifiers: serviceIdentifiers, context: context)
    }
}

final class AutoFillOneTimeCode: AutoFillOneTimeCodeUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let totpService: any TOTPServiceProtocol
    private let completeAutoFill: any CompleteAutoFillUseCase

    init(itemRepository: any ItemRepositoryProtocol,
         totpService: any TOTPServiceProtocol,
         completeAutoFill: any CompleteAutoFillUseCase) {
        self.itemRepository = itemRepository
        self.totpService = totpService
        self.completeAutoFill = completeAutoFill
    }

    func execute(_ item: any ItemIdentifiable,
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 context: ASCredentialProviderExtensionContext) async throws {
        guard #available(iOS 18, *),
              let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                        itemId: item.itemId),
              let loginData = itemContent.loginItem else {
            throw PassError.itemNotFound(item)
        }

        let token = try totpService.generateTotpToken(uri: loginData.totpUri)
        let credential = ASOneTimeCodeCredential(code: token.code)
        try await completeAutoFill(quickTypeBar: false,
                                   identifiers: serviceIdentifiers,
                                   credential: credential,
                                   itemContent: itemContent,
                                   context: context)
    }
}
