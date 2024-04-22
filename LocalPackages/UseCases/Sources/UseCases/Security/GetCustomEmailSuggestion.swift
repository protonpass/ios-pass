//
// GetCustomEmailSuggestion.swift
// Proton Pass - Created on 19/04/2024.
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

import Client
import Entities

public protocol GetCustomEmailSuggestionUseCase: Sendable {
    func execute(breaches: UserBreaches) async throws -> [SuggestedEmail]
}

public extension GetCustomEmailSuggestionUseCase {
    func callAsFunction(breaches: UserBreaches) async throws -> [SuggestedEmail] {
        try await execute(breaches: breaches)
    }
}

public final class GetCustomEmailSuggestion: GetCustomEmailSuggestionUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let validateEmailUseCase: any ValidateEmailUseCase

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                validateEmailUseCase: any ValidateEmailUseCase) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.validateEmailUseCase = validateEmailUseCase
    }

    public func execute(breaches: UserBreaches) async throws -> [SuggestedEmail] {
        guard breaches.customEmails.count < 10 else {
            return []
        }
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()

        let emails = try await itemRepository.getActiveLogInItems()
            .compactMap { encryptedItem -> String? in
                guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                      let loginItem = item.loginItem,
                      validateEmailUseCase(email: loginItem.username),
                      !loginItem.username.lowercased().contains(["proton.", "pm.", "protonmail."]),
                      !breaches.customEmails.map({ $0.email.lowercased() })
                      .contains(loginItem.username.lowercased())
                else {
                    return nil
                }
                return loginItem.username
            }

        let counts = countOccurrences(of: emails)
        let sortedCounts = counts.sorted { $0.value > $1.value }
            .map { SuggestedEmail(email: $0.key, count: $0.value) }
        return Array(sortedCounts.prefix(3))
    }

    func countOccurrences(of array: [String]) -> [String: Int] {
        var counts = [String: Int]()

        for element in array {
            counts[element, default: 0] += 1
        }

        return counts
    }
}

private extension String {
    func contains(_ strings: [String]) -> Bool {
        strings.contains { contains($0) }
    }
}
