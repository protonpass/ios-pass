//
// AutoFillPassword.swift
// Proton Pass - Created on 29/02/2024.
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
import Foundation

protocol AutoFillPasswordUseCase: Sendable {
    func execute(_ item: any ItemIdentifiable,
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 context: ASCredentialProviderExtensionContext) async throws
}

extension AutoFillPasswordUseCase {
    func callAsFunction(_ item: any ItemIdentifiable,
                        serviceIdentifiers: [ASCredentialServiceIdentifier],
                        context: ASCredentialProviderExtensionContext) async throws {
        try await execute(item, serviceIdentifiers: serviceIdentifiers, context: context)
    }
}

final class AutoFillPassword: AutoFillPasswordUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let completeAutoFill: any CompleteAutoFillUseCase

    init(itemRepository: any ItemRepositoryProtocol,
         completeAutoFill: any CompleteAutoFillUseCase) {
        self.itemRepository = itemRepository
        self.completeAutoFill = completeAutoFill
    }

    func execute(_ item: any ItemIdentifiable,
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 context: ASCredentialProviderExtensionContext) async throws {
        guard let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                        itemId: item.itemId),
            let loginData = itemContent.loginItem else {
            throw PassError.itemNotFound(item)
        }

        let credential = ASPasswordCredential(user: loginData.authIdentifier,
                                              password: loginData.password)
        try await completeAutoFill(quickTypeBar: false,
                                   identifiers: serviceIdentifiers,
                                   credential: credential,
                                   userId: itemContent.userId,
                                   itemContent: itemContent,
                                   context: context)
    }
}
