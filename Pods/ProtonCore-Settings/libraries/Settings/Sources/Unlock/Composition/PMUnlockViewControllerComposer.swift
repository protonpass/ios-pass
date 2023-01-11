//
//  PMUnlockViewControllerComposer.swift
//  ProtonCore-Settings - Created on 25.11.2020.
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

import UIKit

public final class PMUnlockViewControllerComposer {
    private init() { }

    /// Creates `PMUnlockViewController`
    /// - Parameters:
    ///   - header: Enum that represents each of the supported apps, e.g.: Drive, Mail...
    ///   - unlocker: Object able to unlock the app, biometrically or using a password
    ///   - logoutManager: Object able to logout
    ///   - logoutAlertSubtitle: Text that alerts the user that a logout action will be carried out and its consequences
    /// - Returns: `PMUnlockViewController` as `UIViewController`
    public static func assemble(
        header: ProtonHeaderViewModel,
        unlocker: Unlocker,
        logoutManager: LogoutManager?,
        logoutAlertSubtitle: String) -> UIViewController {
        let viewModel = UnlockViewModel(
            bioUnlocker: unlocker,
            pinUnlocker: unlocker,
            lockReader: unlocker,
            logout: logoutManager,
            biometricType: .currentType,
            header: header,
            alertSubtitle: logoutAlertSubtitle)
        let viewController = PMUnlockViewController()
        viewController.viewModel = viewModel
        return viewController
    }
}
