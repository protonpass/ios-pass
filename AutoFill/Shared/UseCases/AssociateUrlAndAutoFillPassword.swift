//
// AssociateUrlAndAutoFillPassword.swift
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

protocol AssociateUrlAndAutoFillPasswordUseCase: Sendable {
    func execute(item: any ItemIdentifiable,
                 urls: [URL],
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 context: ASCredentialProviderExtensionContext) async throws
}

extension AssociateUrlAndAutoFillPasswordUseCase {
    func callAsFunction(item: any ItemIdentifiable,
                        urls: [URL],
                        serviceIdentifiers: [ASCredentialServiceIdentifier],
                        context: ASCredentialProviderExtensionContext) async throws {
        try await execute(item: item,
                          urls: urls,
                          serviceIdentifiers: serviceIdentifiers,
                          context: context)
    }
}

final class AssociateUrlAndAutoFillPassword: AssociateUrlAndAutoFillPasswordUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let completeAutoFill: any CompleteAutoFillUseCase

    init(itemRepository: any ItemRepositoryProtocol,
         completeAutoFill: any CompleteAutoFillUseCase) {
        self.itemRepository = itemRepository
        self.completeAutoFill = completeAutoFill
    }

    func execute(item: any ItemIdentifiable,
                 urls: [URL],
                 serviceIdentifiers: [ASCredentialServiceIdentifier],
                 context: ASCredentialProviderExtensionContext) async throws {
        guard let newUrl = urls.first?.schemeAndHost, !newUrl.isEmpty else {
            throw PassError.credentialProvider(.invalidURL(urls.first))
        }

        guard let oldContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                       itemId: item.itemId),
            let oldData = oldContent.loginItem else {
            throw PassError.itemNotFound(item)
        }

        let newLoginData = ItemContentData.login(.init(username: oldData.username,
                                                       password: oldData.password,
                                                       totpUri: oldData.totpUri,
                                                       urls: oldData.urls + [newUrl],
                                                       allowedAndroidApps: oldData.allowedAndroidApps,
                                                       passkeys: oldData.passkeys))
        let newContent = ItemContentProtobuf(name: oldContent.name,
                                             note: oldContent.note,
                                             itemUuid: oldContent.itemUuid,
                                             data: newLoginData,
                                             customFields: oldContent.customFields)
        try await itemRepository.updateItem(oldItem: oldContent.item,
                                            newItemContent: newContent,
                                            shareId: oldContent.shareId)
        let credential = ASPasswordCredential(user: oldData.username,
                                              password: oldData.password)
        try await completeAutoFill(quickTypeBar: false,
                                   identifiers: serviceIdentifiers,
                                   credential: credential,
                                   itemContent: oldContent,
                                   context: context)
    }
}
