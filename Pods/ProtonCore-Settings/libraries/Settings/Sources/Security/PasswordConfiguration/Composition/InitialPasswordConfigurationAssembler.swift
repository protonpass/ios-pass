//
//  InitialPasswordConfigurationAssembler.swift
//  ProtonCore-Settings - Created on 04.10.2020.
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
import ProtonCore_UIFoundations

final class InitialPasswordConfigurationAssembler {
    static func assemble(enabler: PinLockActivator, onSuccess: @escaping (Bool) -> Void) -> (vc: UIViewController, model: PasswordSelector) {
        let viewController = PasswordConfigurationViewController()
        let navigationController = DarkModeAwareNavigationViewController(rootViewController: viewController, style: NavigationBarStyles.sheet)
        let selector = SecurityPasswordSelector()
        let viewModel = InitialPasswordConfigurationViewModel(
            passwordSelector: selector,
            router: InitialPasswordConfigurationRouter(
                view: viewController,
                passwordSelector: selector,
                enabler: enabler,
                onSuccess: onSuccess))
        adapt(viewController, to: viewModel)
        return (navigationController, selector)
    }

    static func adapt(_ viewController: PasswordConfigurationViewController, to viewModel: InitialPasswordConfigurationViewModel) {
        viewController.viewModel = viewModel
        viewModel.rightNavigationButtonEnabled = { [weak viewController] isEnabled in
            viewController?.rightButton.isEnabled = isEnabled
        }
    }
}
