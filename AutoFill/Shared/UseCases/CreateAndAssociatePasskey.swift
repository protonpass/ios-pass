//
// CreateAndAssociatePasskey.swift
// Proton Pass - Created on 28/02/2024.
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
import UseCases

protocol CreateAndAssociatePasskeyUseCase: Sendable {
    func execute(item: any ItemIdentifiable,
                 request: PasskeyCredentialRequest,
                 context: ASCredentialProviderExtensionContext) async throws
}

extension CreateAndAssociatePasskeyUseCase {
    func callAsFunction(item: any ItemIdentifiable,
                        request: PasskeyCredentialRequest,
                        context: ASCredentialProviderExtensionContext) async throws {
        try await execute(item: item, request: request, context: context)
    }
}

final class CreateAndAssociatePasskey: CreateAndAssociatePasskeyUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let createPasskey: any CreatePasskeyUseCase
    private let updateLastUseTimeAndReindex: any UpdateLastUseTimeAndReindexUseCase
    private let completePasskeyRegistration: any CompletePasskeyRegistrationUseCase
    private let userManager: any UserManagerProtocol

    init(itemRepository: any ItemRepositoryProtocol,
         shareRepository: any ShareRepositoryProtocol,
         userManager: any UserManagerProtocol,
         createPasskey: any CreatePasskeyUseCase,
         updateLastUseTimeAndReindex: any UpdateLastUseTimeAndReindexUseCase,
         completePasskeyRegistration: any CompletePasskeyRegistrationUseCase) {
        self.itemRepository = itemRepository
        self.createPasskey = createPasskey
        self.updateLastUseTimeAndReindex = updateLastUseTimeAndReindex
        self.completePasskeyRegistration = completePasskeyRegistration
        self.userManager = userManager
        self.shareRepository = shareRepository
    }

    func execute(item: any ItemIdentifiable,
                 request: PasskeyCredentialRequest,
                 context: ASCredentialProviderExtensionContext) async throws {
        guard let oldItemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                           itemId: item.itemId),
            let oldLoginData = oldItemContent.loginItem,
            let share = try await shareRepository.getShare(shareId: item.shareId)
        else {
            throw PassError.itemNotFound(item)
        }

        let passkeyResponse = try await createPasskey(request,
                                                      bundle: .main,
                                                      device: .current)

        let newPasskeys = oldLoginData.passkeys.appending(passkeyResponse.toPasskey)
        let username = oldLoginData.username.isEmpty ? request.userName : oldLoginData.username
        let newLoginData = ItemContentData.login(.init(email: oldLoginData.email,
                                                       username: username,
                                                       password: oldLoginData.password,
                                                       totpUri: oldLoginData.totpUri,
                                                       urls: oldLoginData.urls,
                                                       allowedAndroidApps: oldLoginData.allowedAndroidApps,
                                                       passkeys: newPasskeys))
        let newContent = ItemContentProtobuf(name: oldItemContent.name,
                                             note: oldItemContent.note,
                                             itemUuid: oldItemContent.itemUuid,
                                             data: newLoginData,
                                             customFields: oldItemContent.customFields)

        try await itemRepository.updateItem(userId: oldItemContent.userId,
                                            oldItem: oldItemContent.item,
                                            newItemContent: newContent,
                                            shareId: item.shareId,
                                            isSharedItem: !share.isVaultRepresentation)
        if let updatedItemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                            itemId: item.itemId) {
            try await updateLastUseTimeAndReindex(item: updatedItemContent,
                                                  date: .now,
                                                  identifiers: [request.serviceIdentifier])
        }

        completePasskeyRegistration(passkeyResponse, context: context)
    }
}
