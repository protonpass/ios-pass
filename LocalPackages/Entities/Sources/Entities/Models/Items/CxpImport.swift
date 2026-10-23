//
// CxpImport.swift
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

import Foundation

public struct CxpImportedVault: Sendable, Hashable {
    /// `nil` when the imported items don't belong to any collection
    public let vault: VaultContent?
    public let items: [ItemContentProtobuf]

    public init(vault: VaultContent?, items: [ItemContentProtobuf]) {
        self.vault = vault
        self.items = items
    }
}

public struct CxpImportResult: Sendable, Hashable {
    public let exporterName: String
    public let vaults: [CxpImportedVault]
    public let hasUnsupportedItems: Bool

    public init(exporterName: String,
                vaults: [CxpImportedVault],
                hasUnsupportedItems: Bool) {
        self.exporterName = exporterName
        self.vaults = vaults
        self.hasUnsupportedItems = hasUnsupportedItems
    }
}
