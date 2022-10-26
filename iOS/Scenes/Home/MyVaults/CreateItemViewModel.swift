//
// CreateItemViewModel.swift
// Proton Pass - Created on 05/08/2022.
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

import Core
import ProtonCore_UIFoundations
import UIComponents
import UIKit

final class CreateItemViewModel: DeinitPrintable {
    deinit { print(deinitMessage) }

    var onSelectedOption: ((CreateNewItemOption) -> Void)?

    init() {}

    func select(option: CreateNewItemOption) {
        onSelectedOption?(option)
    }
}

enum CreateNewItemOption {
    case login, alias, note, password

    var icon: UIImage {
        switch self {
        case .login:
            return IconProvider.keySkeleton
        case .alias:
            return IconProvider.alias
        case .note:
            return IconProvider.note
        case .password:
            return IconProvider.arrowsRotate
        }
    }

    var title: String {
        switch self {
        case .login:
            return "Login"
        case .alias:
            return "Alias"
        case .note:
            return "Note"
        case .password:
            return "Generate password"
        }
    }

    var detail: String {
        switch self {
        case .login:
            return "Keep your username and password secure"
        case .alias:
            return "Hide your identity with a separate email address"
        case .note:
            return "Keep important information secure"
        case .password:
            return "Generate a strong password"
        }
    }

    func toGenericItem() -> GenericItem {
        .init(icon: icon, title: title, detail: .value(detail))
    }
}
