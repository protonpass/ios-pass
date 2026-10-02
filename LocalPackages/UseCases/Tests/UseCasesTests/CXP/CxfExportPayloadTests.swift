//
// CxfExportPayloadTests.swift
// Proton Pass - Created on 02/10/2026.
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

import AuthenticationServices
import Entities
import Foundation
import PassRustCore
import Testing

@Suite(.tags(.cxp))
struct CxfExportPayloadTests {
    @available(iOS 26.0, *)
    @Test
    func `rust export payload decodes into apple credential data`() throws {
        let passSerialization = ProtonPassSerialization()
        let login = ItemContentProtobuf(name: "Proton",
                                        note: "",
                                        itemUuid: UUID().uuidString,
                                        data: .login(.init(email: "john@proton.me",
                                                           username: "john",
                                                           password: "hunter2",
                                                           totpUri: "",
                                                           urls: ["https://proton.me"],
                                                           autofillUrls: [],
                                                           allowedAndroidApps: [],
                                                           passkeys: [])),
                                        customFields: [])
        let vault = VaultContent(name: "Personal", description: "", color: .color1, icon: .icon1)
        let input = try CxfExportInput(vaults: [
            .init(vault: passSerialization.vaultDataDeserialize(data: vault.serializedData()),
                  items: [
                      .init(item: passSerialization.itemDataDeserialize(data: login.data()),
                            metadata: .init(createdAt: 1_700_000_000, modifiedAt: 1_700_000_000, pinned: true))
                  ])
        ],
        exporterRpId: "proton.me",
        exporterDisplayName: "Proton Pass",
        timestamp: 1_700_000_000)

        let payload = try CxfSerialization().export(input: input).payload
        let data = try JSONDecoder().decode(ASExportedCredentialData.self, from: Data(payload.utf8))

        #expect(data.exporterDisplayName == "Proton Pass")
        let item = try #require(data.accounts.first?.items.first)
        #expect(item.title == "Proton")
        #expect(item.favorite == true)
    }
}
