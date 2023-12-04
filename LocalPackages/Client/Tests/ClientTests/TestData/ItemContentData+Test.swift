//
// ItemContentData+Test.swift
// Proton Pass - Created on 20/09/2022.
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

extension ItemContentData {
    static func random() -> ItemContentData {
        let randomInt = Int.random(in: 0...2)
        switch randomInt {
        case 0:
            return .alias
        case 1:
            return .note
        default:
            return .login(.init(username: .random(),
                                password: .random(),
                                totpUri: .random(),
                                urls: .random(randomElement: .random())))
        }
    }
}
