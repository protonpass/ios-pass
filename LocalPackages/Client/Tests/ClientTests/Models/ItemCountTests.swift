//
// ItemCountTests.swift
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
import Testing

@Suite(.tags(.models))
struct ItemCountTests {
    @Test func `items are counted per type, with ssh keys and wifi counted as custom`() {
        let items = [
            item(.login, totpUri: "otpauth://totp/x?secret=ABC"),
            item(.login, totpUri: ""),
            item(.login),
            item(.alias),
            item(.creditCard),
            item(.note),
            item(.identity),
            item(.custom),
            item(.sshKey),
            item(.wifi)
        ]

        let sut = ItemCount(items: items, sharedByMe: 2, sharedWithMe: 3)

        #expect(sut == ItemCount(total: 10,
                                 login: 3,
                                 loginWith2fa: 1,
                                 alias: 1,
                                 creditCard: 1,
                                 note: 1,
                                 identity: 1,
                                 custom: 3,
                                 sharedByMe: 2,
                                 sharedWithMe: 3))
    }

    @Test func `no items give a zero count`() {
        #expect(ItemCount(items: [], sharedByMe: 0, sharedWithMe: 0) == .zero)
    }
}

private extension ItemCountTests {
    func item(_ type: ItemContentType, totpUri: String? = nil) -> ItemUiModel {
        ItemUiModel(itemId: .random(),
                    shareId: "share-1",
                    folderId: nil,
                    type: type,
                    aliasEnabled: false,
                    title: "",
                    description: "",
                    isAlias: type == .alias,
                    totpUri: totpUri,
                    lastUseTime: 0,
                    modifyTime: 0,
                    state: .active,
                    pinned: false,
                    isAliasEnabled: false,
                    shared: false,
                    hasEmail: false,
                    hasUsername: false,
                    hasPassword: false)
    }
}
