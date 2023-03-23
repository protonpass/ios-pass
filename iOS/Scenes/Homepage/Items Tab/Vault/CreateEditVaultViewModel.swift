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

import Client

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

enum VaultMode {
    case create
    case edit(Vault)

    var saveButtonTitle: String {
        switch self {
        case .create:
            return "Create Vault"
        case .edit:
            return "Save"
        }
    }
}

final class CreateEditVaultViewModel: ObservableObject {
    @Published var selectedColor: VaultColor
    @Published var selectedIcon: VaultIcon
    @Published var title: String

    let mode: VaultMode

    init(mode: VaultMode) {
        self.mode = mode
        switch mode {
        case .create:
            selectedColor = .color1
            selectedIcon = .icon1
            title = ""
        case .edit(let vault):
            selectedColor = vault.displayPreferences.color.color
            selectedIcon = vault.displayPreferences.icon.icon
            title = vault.name
        }
    }
}

// MARK: - Public APIs
extension CreateEditVaultViewModel {
    func save() {}
}
