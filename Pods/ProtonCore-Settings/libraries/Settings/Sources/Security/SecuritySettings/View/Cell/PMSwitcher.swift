//
//  PMSwitcher.swift
//  ProtonCore-Settings - Created on 11.11.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public protocol PMSwitcher {
    var isActive: Bool { get }

    func changeValue(to value: Bool, success: @escaping (Bool) -> Void)
}

public struct PinSwitcher: PMSwitcher {
    let locker: Locker
    let router: SettingsSecurityRouter

    public var isActive: Bool {
        locker.isPinProtected
    }

    public func changeValue(to value: Bool, success: @escaping (Bool) -> Void) {
        if value {
            router.configurePassword(enabler: locker, onSuccess: success)
        } else {
            locker.deactivatePin(completion: success)
        }
    }
}

public struct BioSwitcher: PMSwitcher {
    let locker: Locker

    public var isActive: Bool {
        locker.isBioProtected
    }

    public func changeValue(to value: Bool, success: @escaping (Bool) -> Void) {
        if value {
            locker.activateBio(completion: success)
        } else {
            locker.deactivateBio(completion: success)
        }
    }
}

public struct BioSwitcherDisabler: PMSwitcher {
    let locker: Locker

    public var isActive: Bool {
        locker.isBioProtected
    }

    public func changeValue(to value: Bool, success: @escaping (Bool) -> Void) {
        locker.deactivateBio(completion: success)
    }
}
