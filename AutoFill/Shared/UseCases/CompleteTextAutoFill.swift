//
// CompleteTextAutoFill.swift
// Proton Pass - Created on 17/10/2024.
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

protocol CompleteTextAutoFillUseCase: Sendable {
    func execute(_ text: String,
                 context: ASCredentialProviderExtensionContext,
                 userId: String?,
                 item: any ItemIdentifiable) async throws
}

extension CompleteTextAutoFillUseCase {
    func callAsFunction(_ text: String,
                        context: ASCredentialProviderExtensionContext,
                        userId: String?,
                        item: any ItemIdentifiable) async throws {
        try await execute(text, context: context, userId: userId, item: item)
    }
}

final class CompleteTextAutoFill: CompleteTextAutoFillUseCase {
    private let userManager: any UserManagerProtocol
    private let datasource: any LocalTextAutoFillHistoryEntryDatasourceProtocol

    init(userManager: any UserManagerProtocol,
         datasource: any LocalTextAutoFillHistoryEntryDatasourceProtocol) {
        self.userManager = userManager
        self.datasource = datasource
    }

    func execute(_ text: String,
                 context: ASCredentialProviderExtensionContext,
                 userId: String?,
                 item: any ItemIdentifiable) async throws {
        guard #available(iOS 18, *) else { return }
        let userId = if let userId {
            userId
        } else {
            try await userManager.getActiveUserId()
        }
        await context.completeRequest(withTextToInsert: text)
        try await datasource.upsert(item: item, userId: userId, date: .now)
    }
}
