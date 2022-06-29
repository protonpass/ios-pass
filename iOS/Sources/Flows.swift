//
// Flows.swift
// Proton Key - Created on 21/06/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

// swiftlint:disable explicit_enum_raw_value
enum AppFlow: String {
    case logIn
    case home

    init?(deeplink: String) {
        if let flow = AppFlow(rawValue: deeplink) {
            self = flow
            return
        }

        if HomeFlow(deeplink: deeplink) != nil {
            self = .home
        } else if LoginFlow(deeplink: deeplink) != nil {
            self = .logIn
        } else {
            return nil
        }
    }
}

enum LoginFlow: String {
    case home

    init?(deeplink: String) {
        if let flow = LoginFlow(rawValue: deeplink) {
            self = flow
            return
        }

        if HomeFlow(deeplink: deeplink) != nil {
            self = .home
        } else {
            return nil
        }
    }
}

enum HomeFlow: String {
    case favorites
    case vault
    case newKey
    case settings

    init?(deeplink: String) {
        if let flow = HomeFlow(rawValue: deeplink) {
            self = flow
            return
        }

        if FavoritesFlow(deeplink: deeplink) != nil {
            self = .favorites
        } else if VaultFlow(deeplink: deeplink) != nil {
            self = .vault
        } else if NewKeyFlow(deeplink: deeplink) != nil {
            self = .newKey
        } else if SettingsFlow(deeplink: deeplink) != nil {
            self = .settings
        } else {
            return nil
        }
    }
}

enum FavoritesFlow: String {
    case list

    init?(deeplink: String) {
        if let flow = FavoritesFlow(rawValue: deeplink) {
            self = flow
        } else {
            return nil
        }
    }
}

enum VaultFlow: String {
    case list

    init?(deeplink: String) {
        if let flow = VaultFlow(rawValue: deeplink) {
            self = flow
        } else {
            return nil
        }
    }
}

enum NewKeyFlow: String {
    case list

    init?(deeplink: String) {
        if let flow = NewKeyFlow(rawValue: deeplink) {
            self = flow
        } else {
            return nil
        }
    }
}

enum SettingsFlow: String {
    case profile

    init?(deeplink: String) {
        if let flow = SettingsFlow(rawValue: deeplink) {
            self = flow
        } else {
            return nil
        }
    }
}
