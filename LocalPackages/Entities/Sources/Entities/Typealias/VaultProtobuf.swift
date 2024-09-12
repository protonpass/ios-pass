//
// VaultProtobuf.swift
// Proton Pass - Created on 12/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public typealias VaultProtobuf = ProtonPassVaultV1_Vault

public extension VaultProtobuf {
    init(data: Data) throws {
        self = try VaultProtobuf(serializedBytes: data)
    }

    init(name: String,
         description: String,
         color: ProtonPassVaultV1_VaultColor,
         icon: ProtonPassVaultV1_VaultIcon) {
        self.init()
        self.name = name
        description_p = description
        display.color = color
        display.icon = icon
    }

    func data() throws -> Data {
        try serializedData()
    }
}
