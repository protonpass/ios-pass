//
// MapLoginItemTests.swift
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

import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
struct MapLoginItemTests {
    private let key = SymmetricKey(size: .bits256)
    private let sut = MapLoginItem()

    @Test func `each autofillable url gets a password and a one time code identity`() throws {
        let data = LogInItemData.mock(username: "john", urls: ["https://a.com", "https://b.com"])
        let item = try makeEncryptedItem(item: .random(lastUseTime: 42), data: .login(data), key: key)

        let identities = try sut(item: item, symmetricKey: key)

        let passwords = identities.compactMap(\.password)
        let oneTimeCodes = identities.compactMap(\.oneTimeCode)
        #expect(passwords.map(\.url) == ["https://a.com", "https://b.com"])
        #expect(passwords.allSatisfy { $0.username == "john" && $0.lastUseTime == 42 })
        #expect(passwords.allSatisfy { $0.ids.shareId == item.shareId && $0.ids.itemId == item.itemId })
        #expect(oneTimeCodes.map(\.url) == ["https://a.com", "https://b.com"])
    }

    @Test func `the email identifies the credential when the username is empty`() throws {
        let data = LogInItemData.mock(email: "john@proton.me", username: "")
        let item = try makeEncryptedItem(data: .login(data), key: key)

        let identities = try sut(item: item, symmetricKey: key)

        #expect(identities.compactMap(\.password).map(\.username) == ["john@proton.me"])
    }

    @Test func `no password and no totp produce no password or one time code identities`() throws {
        let data = LogInItemData.mock(password: "", totpUri: "")
        let item = try makeEncryptedItem(data: .login(data), key: key)

        #expect(try sut(item: item, symmetricKey: key).isEmpty)
    }

    @Test func `a login without email or username only yields its passkeys`() throws {
        var passkey = Passkey()
        passkey.rpID = "example.com"
        passkey.userName = "john"
        passkey.userHandle = Data([1])
        passkey.credentialID = Data([2])
        let data = LogInItemData.mock(email: "", username: "", passkeys: [passkey])
        let item = try makeEncryptedItem(data: .login(data), key: key)

        let identities = try sut(item: item, symmetricKey: key)

        let passkeys = identities.compactMap(\.passkey)
        #expect(identities.count == 1)
        #expect(passkeys.first?.relyingPartyIdentifier == "example.com")
        #expect(passkeys.first?.userName == "john")
        #expect(passkeys.first?.credentialId == Data([2]))
    }

    @Test func `autofill urls set to never are not indexed`() throws {
        let data = LogInItemData.mock(totpUri: "",
                                      autofillUrls: [
                                          .init(url: "https://a.com", mode: .default),
                                          .init(url: "https://b.com", mode: .never)
                                      ])
        let item = try makeEncryptedItem(data: .login(data), key: key)

        let identities = try sut(item: item, symmetricKey: key)

        #expect(identities.compactMap(\.password).map(\.url) == ["https://a.com"])
    }

    @Test func `a non login item is rejected`() throws {
        let item = try makeEncryptedItem(data: .note, key: key)

        #expect(throws: PassError.credentialProvider(.notLogInItem)) {
            try sut(item: item, symmetricKey: key)
        }
    }
}

private extension CredentialIdentity {
    var password: PasswordCredentialIdentity? {
        if case let .password(identity) = self {
            identity
        } else {
            nil
        }
    }

    var oneTimeCode: OneTimeCodeIdentity? {
        if case let .oneTimeCode(identity) = self {
            identity
        } else {
            nil
        }
    }

    var passkey: PasskeyCredentialIdentity? {
        if case let .passkey(identity) = self {
            identity
        } else {
            nil
        }
    }
}
