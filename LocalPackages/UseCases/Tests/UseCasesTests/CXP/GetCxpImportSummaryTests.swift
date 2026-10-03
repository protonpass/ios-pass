//
// GetCxpImportSummaryTests.swift
// Proton Pass - Created on 03/10/2026.
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

import Entities
import EntitiesMocks
import Foundation
import Testing
import UseCases

@Suite(.tags(.cxp))
struct GetCxpImportSummaryTests {
    let sut: any GetCxpImportSummaryUseCase = GetCxpImportSummary()

    @Test func `no items produce no rows`() {
        #expect(sut(items: []).isEmpty)
    }

    @Test func `rows follow category order and omit empty categories`() {
        let items: [ItemContentProtobuf] = [
            .item(data: .creditCard(.init(cardholderName: "",
                                          type: .unspecified,
                                          number: "",
                                          verificationNumber: "",
                                          expirationDate: "",
                                          pin: ""))),
            .item(data: .note),
            .item(data: .alias),
            .item(data: .note)
        ]

        #expect(sut(items: items) == [
            .init(category: .note, total: 2),
            .init(category: .alias, total: 1),
            .init(category: .creditCard, total: 1)
        ])
    }

    @Test func `logins count their passkeys and totp uri`() {
        let items: [ItemContentProtobuf] = [
            .item(data: .login(.mock(totpUri: "otpauth://totp/a", passkeys: [.init(), .init()]))),
            .item(data: .login(.mock(totpUri: "", passkeys: [])))
        ]

        #expect(sut(items: items) == [
            .init(category: .login, total: 2),
            .init(category: .totp, total: 1),
            .init(category: .passkey, total: 2)
        ])
    }

    @Test func `totp custom fields are counted for any item type`() {
        let items: [ItemContentProtobuf] = [
            .item(data: .note, customFields: [.totp, .totp, .text]),
            .item(data: .login(.mock(totpUri: "otpauth://totp/a")), customFields: [.totp])
        ]

        #expect(sut(items: items) == [
            .init(category: .login, total: 1),
            .init(category: .totp, total: 4),
            .init(category: .note, total: 1)
        ])
    }

    @Test func `ssh keys, wifi networks and custom items are grouped as custom`() {
        let items: [ItemContentProtobuf] = [
            .item(data: .sshKey(.init(privateKey: "", publicKey: "", extraSections: []))),
            .item(data: .wifi(.init(ssid: "", password: "", security: .unspecified, extraSections: []))),
            .item(data: .custom(.init(sections: [])))
        ]

        #expect(sut(items: items) == [.init(category: .custom, total: 3)])
    }
}

private extension ItemContentProtobuf {
    static func item(data: ItemContentData, customFields: [CustomField] = []) -> Self {
        .init(name: "", note: "", itemUuid: UUID().uuidString, data: data, customFields: customFields)
    }
}

private extension CustomField {
    static var totp: Self {
        .init(title: "", type: .totp, content: "")
    }

    static var text: Self {
        .init(title: "", type: .text, content: "")
    }
}
