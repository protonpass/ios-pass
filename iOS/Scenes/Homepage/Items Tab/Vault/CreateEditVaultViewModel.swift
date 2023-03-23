//
// CreateEditVaultViewModel.swift
// Proton Pass - Created on 23/03/2023.
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

import Foundation

enum VaultColorIcon {
    case color(VaultColor)
    case icon(VaultIcon)

    static var allCases: [VaultColorIcon] {
        let colors = VaultColor.allCases.map { VaultColorIcon.color($0) }
        let icons = VaultIcon.allCases.map { VaultColorIcon.icon($0) }
        return colors + icons
    }
}

extension VaultColorIcon: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .color(let color):
            hasher.combine(color)
        case .icon(let icon):
            hasher.combine(icon)
        }
    }
}

final class CreateEditVaultViewModel: ObservableObject {
    @Published var selectedColor: VaultColor = .color1
    @Published var selectedIcon: VaultIcon = .icon1
    @Published var title = ""
}

// MARK: - Public APIs
extension CreateEditVaultViewModel {
    func save() {}
}
