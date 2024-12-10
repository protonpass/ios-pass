//
// AESGCM+ConvenientSealOpen.swift
// Proton Pass - Created on 28/02/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Foundation

public enum AssociatedData: String {
    case itemContent = "itemcontent"
    case itemKey = "itemkey"
    case vaultContent = "vaultcontent"
    case linkKey = "linkkey"
    case fileData = "filedata"

    var data: Data { rawValue.data(using: .utf8) ?? .init() }
}

public extension AES.GCM {
    static func seal(_ data: Data, key: Data, associatedData: AssociatedData) throws -> SealedBox {
        try AES.GCM.seal(data, using: .init(data: key), authenticating: associatedData.data)
    }

    static func open(_ data: Data, key: Data, associatedData: AssociatedData) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: .init(data: key), authenticating: associatedData.data)
    }
}
