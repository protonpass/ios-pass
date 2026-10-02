//
// ParseCxpImportTests.swift
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

@testable import UseCases
import AuthenticationServices
import Entities
import Foundation
import Testing

@Suite(.tags(.cxp))
struct ParseCxpImportTests {
    let sut = ParseCxpImport()

    @Test
    func `group items by collection`() throws {
        let result = try sut.parse(payload: CxfFixture.multiVault, exporterName: "Exporter")

        #expect(result.exporterName == "Exporter")
        #expect(result.vaults.compactMap(\.vault?.name) == ["Vault One", "Vault Two"])
        #expect(result.vaults.map { $0.items.map(\.name) } == [["Item One"], ["Item Two"]])
        #expect(result.vaults.flatMap(\.items).allSatisfy { $0.contentData.type == .note })
        #expect(result.vaults.flatMap(\.items).map(\.note) == ["Note one", "Note two"])
    }

    @Test
    func `map login with passkey and totp`() throws {
        let result = try sut.parse(payload: CxfFixture.loginPasskeyTotp, exporterName: "Exporter")

        let item = try #require(result.vaults.first?.items.first)
        guard case let .login(login) = item.contentData else {
            Issue.record("Expected a login item")
            return
        }
        #expect(item.name == "My Passkey Login")
        #expect(login.password == "hunter2")
        #expect(login.urls == ["https://example.com"])
        #expect(login.passkeys.count == 1)
        #expect(!login.totpUri.isEmpty)
    }

    @Test
    func `throw on malformed payload`() {
        #expect(throws: (any Error).self) {
            try sut.parse(payload: "{}", exporterName: "Exporter")
        }
    }

    @available(iOS 26.0, *)
    @Test
    func `apple credential data round-trips to a parsable payload`() throws {
        let data = try JSONDecoder.cxf.decode(ASExportedCredentialData.self,
                                              from: Data(CxfFixture.loginPasskeyTotp.utf8))
        let payload = try #require(try String(bytes: JSONEncoder.cxf.encode(data), encoding: .utf8))

        let result = try sut.parse(payload: payload, exporterName: data.exporterDisplayName)

        #expect(result.exporterName == "Example Exporter")
        #expect(result.vaults.flatMap(\.items).count == 1)
    }

    @available(iOS 26.0, *)
    @Test
    func `apple credential data with fractional timestamp encodes to a parsable payload`() throws {
        let fixture = CxfFixture.loginPasskeyTotp.replacing("1700000000", with: "1700000000.823753")
        let data = try JSONDecoder.cxf.decode(ASExportedCredentialData.self, from: Data(fixture.utf8))
        let payload = try #require(try String(bytes: JSONEncoder.cxf.encode(data), encoding: .utf8))

        let result = try sut.parse(payload: payload, exporterName: data.exporterDisplayName)

        #expect(data.timestamp.timeIntervalSince1970.rounded(.down) == 1_700_000_000)
        #expect(result.vaults.flatMap(\.items).count == 1)
    }
}

private enum CxfFixture {
    static let multiVault = """
    {
      "version": { "major": 1, "minor": 0 },
      "exporterRpId": "example.com",
      "exporterDisplayName": "Example Exporter",
      "timestamp": 1700000000,
      "accounts": [
        {
          "id": "YWNjb3VudC0wMQ",
          "username": "",
          "email": "",
          "collections": [
            { "id": "Y29sbC0wMQ", "title": "Vault One", "items": [{ "item": "aXRlbS1vbmU" }] },
            { "id": "Y29sbC0wMg", "title": "Vault Two", "items": [{ "item": "aXRlbS10d28" }] }
          ],
          "items": [
            {
              "id": "aXRlbS1vbmU",
              "title": "Item One",
              "credentials": [
                { "type": "note", "content": { "fieldType": "string", "value": "Note one" } }
              ]
            },
            {
              "id": "aXRlbS10d28",
              "title": "Item Two",
              "credentials": [
                { "type": "note", "content": { "fieldType": "string", "value": "Note two" } }
              ]
            }
          ]
        }
      ]
    }
    """

    static let loginPasskeyTotp = """
    {
      "version": { "major": 1, "minor": 0 },
      "exporterRpId": "example.com",
      "exporterDisplayName": "Example Exporter",
      "timestamp": 1700000000,
      "accounts": [
        {
          "id": "YWNjb3VudC0wMQ",
          "username": "jane",
          "email": "jane@example.com",
          "collections": [
            { "id": "Y29sbC0wMQ", "title": "Personal", "items": [{ "item": "aXRlbS0wMQ" }] }
          ],
          "items": [
            {
              "id": "aXRlbS0wMQ",
              "title": "My Passkey Login",
              "scope": { "urls": ["https://example.com"], "androidApps": [] },
              "credentials": [
                {
                  "type": "basic-auth",
                  "username": { "fieldType": "string", "value": "jane@example.com" },
                  "password": { "fieldType": "concealed-string", "value": "hunter2" }
                },
                {
                  "type": "passkey",
                  "credentialId": "AQIDBA",
                  "rpId": "example.com",
                  "username": "jane",
                  "userDisplayName": "Jane Doe",
                  "userHandle": "BQYHCA",
                  "key": "MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgGis8TV5vcIGSo7TF1uf4CREiM0RVZneImaq7zN3u_wGhRANCAARu620jAHgTkb-xEcH1VTDNoZmGAsHeDb11GWRxb3LPj_mWMwSzpAlSkG7mp_1Ydzo3LMh-GkbClEppQ1LYt3RP"
                },
                {
                  "type": "totp",
                  "secret": "JBSWY3DPEHPK3PXP",
                  "period": 30,
                  "digits": 6,
                  "algorithm": "sha1",
                  "issuer": "Example"
                }
              ]
            }
          ]
        }
      ]
    }
    """
}
