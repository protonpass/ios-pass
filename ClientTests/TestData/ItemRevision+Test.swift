//
// ItemRevision+Test.swift
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

@testable import Client

extension ItemRevisionState {
    static func random() -> Int16 {
        allCases.map { $0.rawValue }.randomElement() ?? Self.active.rawValue
    }
}

extension ItemRevision {
    static func random(itemId: String? = nil) -> ItemRevision {
        .init(itemID: itemId ?? .random(),
              revision: .random(in: 0...100),
              contentFormatVersion: .random(in: 0...100),
              rotationID: .random(),
              content: .random(),
              userSignature: .random(),
              itemKeySignature: .random(),
              state: ItemRevisionState.random(),
              signatureEmail: .random(),
              aliasEmail: .random(),
              createTime: .random(in: 0...1_000_000),
              modifyTime: .random(in: 0...1_000_000))
    }
}
