//
// ShareKey+Test.swift
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

@testable import Client
import Entities

extension ShareKey {
    static func random(keyRotation: Int64? = nil) -> ShareKey {
        .init(createTime: .random(in: 1_000_000...2_000_000),
              key: .random(),
              keyRotation: keyRotation ?? .random(in: 1...1_000_000),
              userKeyID: .random())
    }
}
