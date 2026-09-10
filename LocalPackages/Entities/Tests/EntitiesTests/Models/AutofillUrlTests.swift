//
// AutofillUrlTests.swift
// Proton Pass - Created on 10/09/2026.
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

@testable import Entities
import Testing

private extension ItemContentData {
    var loginData: LogInItemData? {
        if case let .login(data) = self {
            return data
        }
        return nil
    }
}

private func login(urls: [String], autofillUrls: [AutofillUrl]) -> LogInItemData {
    LogInItemData(email: "",
                  username: "",
                  password: "",
                  totpUri: "",
                  urls: urls,
                  autofillUrls: autofillUrls,
                  allowedAndroidApps: [],
                  passkeys: [])
}

@Suite(.tags(.entity))
struct AutofillUrlTests {
    // MARK: - resolvedAutofillUrls

    @Test func `an item predating the feature falls back to urls as default mode`() {
        let sut = login(urls: ["https://a.com", "https://b.com"], autofillUrls: [])

        #expect(sut.resolvedAutofillUrls == [.init(url: "https://a.com", mode: .default),
                                             .init(url: "https://b.com", mode: .default)])
    }

    @Test func `an item carrying autofillUrls is returned untouched`() {
        let autofillUrls = [AutofillUrl(url: "https://a.com", mode: .never)]
        let sut = login(urls: ["https://a.com", "https://stale.com"], autofillUrls: autofillUrls)

        #expect(sut.resolvedAutofillUrls == autofillUrls)
    }

    @Test func `an item with no website at all resolves to nothing`() {
        #expect(login(urls: [], autofillUrls: []).resolvedAutofillUrls.isEmpty)
    }

    // MARK: - autofillableUrls

    @Test func `a never url is excluded from autofill but keeps its place in urls`() {
        let sut = login(urls: [],
                        autofillUrls: [.init(url: "https://fill.com", mode: .default),
                                       .init(url: "https://bank.com", mode: .never)])

        #expect(sut.autofillableUrls == ["https://fill.com"])
    }

    @Test func `a mode this build does not know stays autofillable`() {
        let sut = login(urls: [], autofillUrls: [.init(url: "https://a.com", mode: .unrecognized(9))])

        #expect(sut.autofillableUrls == ["https://a.com"])
    }

    @Test func `a legacy item is fully autofillable`() {
        #expect(login(urls: ["https://a.com"], autofillUrls: []).autofillableUrls == ["https://a.com"])
    }

    // MARK: - Protobuf round trip

    @Test(arguments: [AutofillUrlMode.default,
                      .exact,
                      .never,
                      .startWith,
                      .pattern,
                      .regularExpression,
                      .exactPath])
    func `every known mode survives a protobuf round trip`(mode: AutofillUrlMode) throws {
        let data = ItemContentData.login(login(urls: [],
                                               autofillUrls: [.init(url: "https://a.com", mode: mode)]))
        let protobuf = ItemContentProtobuf(name: "", note: "", itemUuid: "", data: data, customFields: [])

        let decoded = try #require(protobuf.contentData.loginData)
        #expect(decoded.autofillUrls == [.init(url: "https://a.com", mode: mode)])
    }

    /// A mode added to the proto after this build must come back out on the wire unchanged.
    /// Collapsing it to `.default` would silently widen a stricter rule set from another
    /// platform the first time the item is opened and saved here.
    @Test func `an unknown wire mode is preserved rather than widened to default`() throws {
        var wireUrl = ProtonPassItemV1_AutofillUrl()
        wireUrl.url = "https://a.com"
        wireUrl.mode = .UNRECOGNIZED(9)
        var incoming = ItemContentProtobuf()
        incoming.content.login = .init()
        incoming.content.login.autofillUrls = [wireUrl]

        let decoded = try #require(incoming.contentData.loginData)
        #expect(decoded.autofillUrls.first?.mode == .unrecognized(9))

        let reEncoded = ItemContentProtobuf(name: "",
                                            note: "",
                                            itemUuid: "",
                                            data: .login(decoded),
                                            customFields: [])
        #expect(reEncoded.content.login.autofillUrls.first?.mode.rawValue == 9)
    }
}
