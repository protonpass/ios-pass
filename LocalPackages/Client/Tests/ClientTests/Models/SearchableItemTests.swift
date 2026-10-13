//
// SearchableItemTests.swift
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

@testable import Client
import Entities
import EntitiesMocks
import Testing

@Suite(.tags(.models))
struct SearchableItemTests {
    @Test func `a login exposes its first url, email and username for search`() {
        let data = LogInItemData.mock(email: "john@proton.me",
                                      username: "john",
                                      urls: ["https://one.com", "https://two.com"])

        let sut = SearchableItem(from: makeItemContent(data: .login(data)), allVaults: [])

        #expect(sut.url == "https://one.com")
        #expect(sut.requiredExtras == ["john@proton.me", "john"])
        #expect(sut.optionalExtras == ["https://one.com", "https://two.com"])
    }

    @Test func `name and note are trimmed`() {
        let sut = SearchableItem(from: makeItemContent(name: "  Name\n", note: "\tNote  ", data: .note),
                                 allVaults: [])

        #expect(sut.name == "Name")
        #expect(sut.note == "Note")
    }

    @Test func `the vault is only attached when the user has more than one vault`() {
        let vault = Share.random(shareID: "share-1", owner: true)
        let otherVault = Share.random(shareID: "share-2")
        let content = makeItemContent(shareId: "share-1", data: .note)

        let withOneVault = SearchableItem(from: content, allVaults: [vault])
        let withTwoVaults = SearchableItem(from: content, allVaults: [vault, otherVault])

        #expect(withOneVault.vault == nil)
        #expect(withOneVault.owner)
        #expect(withTwoVaults.vault?.shareId == "share-1")
    }

    @Test func `text custom fields are searchable with their content, other fields only by title`() {
        let customFields = [
            CustomField(title: "Pin", type: .text, content: "1234"),
            CustomField(title: "Secret", type: .hidden, content: "s3cr3t"),
            CustomField(title: "OTP", type: .totp, content: "otpauth://totp/x?secret=ABC")
        ]

        let sut = SearchableItem(from: makeItemContent(data: .note, customFields: customFields), allVaults: [])

        #expect(sut.optionalExtras == ["Pin: 1234", "Secret", "OTP"])
    }

    @Test(arguments: ["netflix", "NETFLIX", "Nétflix"])
    func `search matches the title case and diacritic insensitively`(term: String) async throws {
        let sut = SearchableItem(from: makeItemContent(name: "Netflix", data: .note), allVaults: [])

        let results = try await [sut].result(for: term)

        #expect(results.map(\.itemId) == [sut.itemId])
    }

    @Test(arguments: ["office", "john.doe", "example.org", "alias@sl.me", "4321"])
    func `search matches the note, username, urls, alias email and text custom fields`(term: String) async throws {
        let sut = SearchableItem(from: searchableLogin(), allVaults: [])

        let results = try await [sut].result(for: term)

        #expect(results.map(\.itemId) == [sut.itemId])
    }

    @Test(arguments: ["hunter2", "s3cr3t", ""])
    func `search never matches passwords, hidden field content or an empty term`(term: String) async throws {
        let sut = SearchableItem(from: searchableLogin(), allVaults: [])

        let results = try await [sut].result(for: term)

        #expect(results.isEmpty)
    }
}

private extension SearchableItemTests {
    func makeItemContent(shareId: String = "share-1",
                         name: String = "Name",
                         note: String = "",
                         data: ItemContentData,
                         customFields: [CustomField] = [],
                         aliasEmail: String? = nil) -> ItemContent {
        ItemContent(shareId: shareId,
                    itemUuid: .random(),
                    userId: "user-1",
                    item: .random(aliasEmail: aliasEmail),
                    name: name,
                    note: note,
                    contentData: data,
                    customFields: customFields,
                    simpleLoginNote: nil)
    }

    func searchableLogin() -> ItemContent {
        let data = LogInItemData.mock(email: "",
                                      username: "john.doe",
                                      password: "hunter2",
                                      urls: ["https://example.org"])
        return makeItemContent(name: "Unrelated",
                               note: "Office laptop",
                               data: .login(data),
                               customFields: [
                                   CustomField(title: "Pin", type: .text, content: "4321"),
                                   CustomField(title: "Recovery", type: .hidden, content: "s3cr3t")
                               ],
                               aliasEmail: "alias@sl.me")
    }
}
