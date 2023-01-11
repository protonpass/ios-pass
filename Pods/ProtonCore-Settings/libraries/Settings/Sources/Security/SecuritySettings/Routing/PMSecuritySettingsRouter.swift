//
//  PMSecuritySettingsRouter.swift
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

final class PMSecuritySettingsRouter: SettingsSecurityRouter {
    weak var view: UIViewController?
    var refreshSections: (() -> Void)?

    init(view: UIViewController) {
        self.view = view
    }

    func popView() {
        view?.navigationController?.popViewController(animated: true)
    }

    func configurePassword(enabler: PinLockActivator, onSuccess: @escaping (Bool) -> Void) {
        let (viewController, _) = InitialPasswordConfigurationAssembler.assemble(enabler: enabler, onSuccess: onSuccess)
        view?.present(viewController, animated: true, completion: nil)
    }
}
