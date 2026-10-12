//
// ParseCxpImport.swift
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

public protocol ParseCxpImportUseCase: Sendable {
    @available(iOS 26.0, *)
    @concurrent
    func callAsFunction(token: UUID) async throws -> CxpImportResult
}

public struct ParseCxpImport: ParseCxpImportUseCase {
    private let cxfSerialization: any CxfSerializationProtocol
    private let passSerialization: any ProtonPassSerializationProtocol

    public init(cxfSerialization: any CxfSerializationProtocol = CxfSerialization(),
                passSerialization: any ProtonPassSerializationProtocol = ProtonPassSerialization()) {
        self.cxfSerialization = cxfSerialization
        self.passSerialization = passSerialization
    }

    @available(iOS 26.0, *)
    @concurrent
    public func callAsFunction(token: UUID) async throws -> CxpImportResult {
        let data = try await ASCredentialImportManager().importCredentials(token: token)
        guard let payload = try String(bytes: JSONEncoder.cxf.encode(data), encoding: .utf8) else {
            throw PassError.unexpectedError
        }
        return try parse(payload: payload, exporterName: data.exporterDisplayName)
    }

    func parse(payload: String, exporterName: String) throws -> CxpImportResult {
        let result = try cxfSerialization.import(payload: payload)
        let vaults = try result.vaults.map { imported in
            let vault = try imported.vault.map {
                try VaultContent(data: passSerialization.vaultDataSerialize(vault: $0))
            }
            let items = try imported.items.map {
                try ItemContentProtobuf(data: passSerialization.itemDataSerialize(item: $0))
            }
            return CxpImportedVault(vault: vault, items: items)
        }
        return .init(exporterName: exporterName, vaults: vaults)
    }
}
