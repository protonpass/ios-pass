//
// GetCustomEmailSuggestionTests.swift
// Proton Pass - Created on 05/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import ClientMocks
import CryptoKit
import Entities
import EntitiesMocks
import Testing
import UseCases

/// The real `ValidateEmail` is backed by PassRustCore.
private struct ValidateEmailStub: ValidateEmailUseCase {
    func execute(email: String) -> Bool {
        email.contains("@")
    }
}

@Suite(.tags(.useCase, .monitor))
struct GetCustomEmailSuggestionTests {
    private let key = SymmetricKey(size: .bits256)
    private let itemRepository = ItemRepositoryProtocolMock()

    @Test func `suggestions are the three most used emails, ties broken alphabetically`() async throws {
        itemRepository.stubbedGetAllItemsResult = try [
            login("b@x.com"), login("b@x.com"), login("B@X.com"),
            login("a@x.com"), login("a@x.com"),
            login("c@x.com"), login("c@x.com"),
            login("d@x.com")
        ]

        let suggestions = try await makeSUT()(userId: "user-1", monitoredCustomEmails: [], protonAddresses: [])

        #expect(suggestions == [
            .init(email: "b@x.com", count: 3),
            .init(email: "a@x.com", count: 2),
            .init(email: "c@x.com", count: 2)
        ])
    }

    @Test func `monitored, proton, alias, invalid, trashed and non login emails are never suggested`() async throws {
        itemRepository.stubbedGetAllItemsResult = try [
            login("monitored@x.com"),
            login("proton@proton.me"),
            login("alias@sl.me"),
            makeEncryptedItem(item: .random(state: .active, aliasEmail: "ALIAS@sl.me", flags: 0),
                              data: .alias,
                              key: key),
            login("not-an-email"),
            login("trashed@x.com", state: .trashed),
            login("kept@x.com")
        ]
        let monitored = CustomEmail(customEmailID: "1",
                                    email: "Monitored@x.com",
                                    verified: true,
                                    breachCounter: 0,
                                    flags: 0,
                                    lastBreachTime: nil)
        let protonAddress = ProtonAddress(addressID: "1",
                                          email: "proton@proton.me",
                                          breachCounter: 0,
                                          flags: 0,
                                          lastBreachTime: nil)

        let suggestions = try await makeSUT()(userId: "user-1",
                                              monitoredCustomEmails: [monitored],
                                              protonAddresses: [protonAddress])

        #expect(suggestions == [.init(email: "kept@x.com", count: 1)])
    }

    @Test func `no suggestion once ten emails are monitored`() async throws {
        itemRepository.stubbedGetAllItemsResult = try [login("kept@x.com")]
        let monitored = (0..<10).map {
            CustomEmail(customEmailID: "\($0)",
                        email: "\($0)@x.com",
                        verified: true,
                        breachCounter: 0,
                        flags: 0,
                        lastBreachTime: nil)
        }

        let suggestions = try await makeSUT()(userId: "user-1",
                                              monitoredCustomEmails: monitored,
                                              protonAddresses: [])

        #expect(suggestions.isEmpty)
    }
}

private extension GetCustomEmailSuggestionTests {
    func makeSUT() -> GetCustomEmailSuggestion {
        let symmetricKeyProvider = SymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = key
        return GetCustomEmailSuggestion(itemRepository: itemRepository,
                                        symmetricKeyProvider: symmetricKeyProvider,
                                        validateEmailUseCase: ValidateEmailStub())
    }

    func login(_ email: String, state: ItemState = .active) throws -> SymmetricallyEncryptedItem {
        try makeEncryptedItem(item: .random(state: state, flags: 0),
                              data: .login(.mock(email: email)),
                              key: key)
    }
}
