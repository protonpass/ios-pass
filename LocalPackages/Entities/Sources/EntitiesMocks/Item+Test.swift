//
// Item+Test.swift
// Proton Pass - Created on 10/08/2022.
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

import Entities

public extension ItemState {
    static func random() -> Int64 {
        allCases.map(\.rawValue).randomElement() ?? active.rawValue
    }
}

public extension Item {
    static func random(itemId: String? = nil,
                       state: ItemState? = nil,
                       aliasEmail: String? = nil,
                       pinned: Bool = false,
                       keyRotation: Int64 = .random(in: 0...100),
                       lastUseTime: Int64 = .random(in: 0...1_000_000),
                       modifyTime: Int64 = .random(in: 0...1_000_000),
                       flags: Int = .random(in: 0...1_000_000),
                       shareCount: Int = .random(in: 0...5)) -> Item {
        .init(itemID: itemId ?? .random(),
              revision: .random(in: 0...100),
              contentFormatVersion: .random(in: 0...100),
              keyRotation: keyRotation,
              content: .random(),
              itemKey: .random(),
              state: state?.rawValue ?? ItemState.random(),
              pinned: pinned, 
              pinTime: nil,
              aliasEmail: aliasEmail,
              createTime: .random(in: 0...1_000_000),
              modifyTime: modifyTime,
              lastUseTime: lastUseTime,
              revisionTime: .random(in: 0...1_000_000),
              flags: flags,
              shareCount: shareCount)
    }
}
