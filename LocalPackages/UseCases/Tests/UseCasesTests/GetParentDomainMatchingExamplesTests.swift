//
// GetParentDomainMatchingExamplesTests.swift
// Proton Pass - Created on 08/10/2026.
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
//

import Entities
import Testing
import UseCases

@Suite(.tags(.useCase))
struct GetParentDomainMatchingExamplesTests {
    private let sut: any GetParentDomainMatchingExamplesUseCase =
        GetParentDomainMatchingExamples(getRootDomain: GetRootDomain())

    @Test(arguments: [
        (input: "https://account.acme.com", root: "acme.com", otherTld: "acme.net"),
        (input: "account.acme.com", root: "acme.com", otherTld: "acme.net"),
        (input: "https://shop.example.co.uk/path?query=1", root: "example.co.uk", otherTld: "example.net"),
        (input: "https://www.example.net", root: "example.net", otherTld: "example.com")
    ])
    func `examples are built from the root domain of the url`(input: String,
                                                              root: String,
                                                              otherTld: String) {
        #expect(sut(for: input) == [
            .init(url: "https://\(root)", suggested: true),
            .init(url: "https://subdomain.\(root)", suggested: true),
            .init(url: "https://\(otherTld)", suggested: false),
            .init(url: "https://google.com", suggested: false)
        ])
    }

    @Test
    func `examples keep the scheme of the url`() {
        #expect(sut(for: "http://login.acme.com").allSatisfy { $0.url.hasPrefix("http://") })
    }

    @Test
    func `unrelated example avoids the url own domain`() {
        #expect(sut(for: "https://accounts.google.com").last == .init(url: "https://proton.me",
                                                                      suggested: false))
    }

    @Test(arguments: ["", "a", "localhost"])
    func `invalid urls have no examples`(input: String) {
        #expect(sut(for: input).isEmpty)
    }
}
