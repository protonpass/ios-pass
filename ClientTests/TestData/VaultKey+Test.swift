//
// VaultKey+Test.swift
// Proton Pass - Created on 03/08/2022.
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

import Client

extension VaultKey {
    static func random(rotationId: String? = nil) -> VaultKey {
        .init(rotationID: rotationId ?? .random(),
              rotation: .random(in: 1...100),
              key: .random(),
              keyPassphrase: .random(),
              keySignature: .random(),
              createTime: .random(in: 1...100))
    }
}
