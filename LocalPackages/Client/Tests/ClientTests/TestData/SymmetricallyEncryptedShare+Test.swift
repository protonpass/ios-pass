//
// SymmetricallyEncryptedShare+Test.swift
// Proton Pass - Created on 11/04/2023.
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

@testable import Client

extension SymmetricallyEncryptedShare {
    static func random(shareId: String? = nil,
                       vaultId: String? = nil,
                       contentKeyRotation: Int64? = nil) -> SymmetricallyEncryptedShare {
        .init(encryptedContent: .random(),
              share: .random(shareId: shareId,
                             vaultId: vaultId,
                             contentKeyRotation: contentKeyRotation))
    }
}
