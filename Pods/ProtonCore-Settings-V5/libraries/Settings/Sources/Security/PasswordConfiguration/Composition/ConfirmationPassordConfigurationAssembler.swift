//
//  ConfirmationPassordConfigurationAssembler.swift
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

// swiftlint:disable type_name
final class ConfirmationPassordConfigurationAssembler {
    static func assemble(with selector: PasswordSelector, enabler: PinLockActivator, onSuccess: @escaping (Bool) -> Void) -> UIViewController {
        let viewController = PasswordConfigurationViewController()
        let viewModel = ConfirmationPasswordConfigurationViewModel(
            passwordSelector: selector,
            router: ConfirmationPasswordConfigurationRouter(
                view: viewController,
                onSuccess: onSuccess),
            enabler: enabler)

        adapt(viewController, to: viewModel)
        return viewController
    }

    static func adapt(_ viewController: PasswordConfigurationViewController, to viewModel: ConfirmationPasswordConfigurationViewModel) {
        viewController.viewModel = viewModel
        viewModel.rightNavigationButtonEnabled = { [weak viewController] isEnabled in
            viewController?.rightButton.isEnabled = isEnabled
        }
        viewModel.onErrorReceived = { [weak viewController] error in
            viewController?.showError(error)
        }
    }
}
