//
//  InitialPasswordConfigurationRouter.swift
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

final class InitialPasswordConfigurationRouter: SecurityPasswordRouter {
    weak var view: UIViewController?
    private let passwordSelector: PasswordSelector
    private let enabler: PinLockActivator
    private let onSuccess: (Bool) -> Void

    init(view: UIViewController, passwordSelector: PasswordSelector, enabler: PinLockActivator, onSuccess: @escaping (Bool) -> Void) {
        self.view = view
        self.passwordSelector = passwordSelector
        self.enabler = enabler
        self.onSuccess = onSuccess
    }

    func advance() {
        let nextVC = ConfirmationPassordConfigurationAssembler.assemble(with: passwordSelector, enabler: enabler, onSuccess: onSuccess)
        view?.navigationController?.pushViewController(nextVC, animated: true)
    }

    func withdraw() {
        view?.dismiss(animated: true, completion: nil)
    }

    func finishWithSuccess(_ success: Bool) {
        onSuccess(success)
    }
}
