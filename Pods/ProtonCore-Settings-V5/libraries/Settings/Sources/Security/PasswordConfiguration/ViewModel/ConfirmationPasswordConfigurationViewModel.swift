//
//  ConfirmationPasswordConfigurationViewModel.swift
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

import Foundation
import ProtonCore_UIFoundations

// swiftlint:disable type_name
final class ConfirmationPasswordConfigurationViewModel: PasswordConfigurationViewModel {
    private let router: SecurityPasswordRouter
    private let passwordSelector: PasswordSelector

    var rightNavigationButtonEnabled: Observer<Bool>?
    var onErrorReceived: Observer<String>?
    private let enabler: PinLockActivator
    private var didEnablePassword = false

    init(passwordSelector: PasswordSelector, router: SecurityPasswordRouter, enabler: PinLockActivator) {
        self.router = router
        self.passwordSelector = passwordSelector
        self.enabler = enabler
    }

    func userInputDidChange(to text: String) {
        do {
            try passwordSelector.setConfirmationPassword(to: text)
            rightNavigationButtonEnabled?(true)
        } catch {
            rightNavigationButtonEnabled?(false)
        }
    }

    func withdrawFromScreen() {
        router.withdraw()
    }

    func advance() {
        switch passwordSelector.getPassword() {
        case .success(let password):
            enabler.activatePin(pin: password) { [weak self] isSuccess in
                self?.didEnablePassword = isSuccess
                if isSuccess {
                    self?.router.advance()
                } else {
                    self?.onErrorReceived?("Something went wrong!")
                }
            }
        case .failure(let error as NSError):
            onErrorReceived?(error.domain)
            rightNavigationButtonEnabled?(false)
        }
    }

    func viewWillDissapear() {
        router.finishWithSuccess(didEnablePassword)
    }

    var title: String {
        "Use PIN code"
    }

    var buttonText: String {
        "Save"
    }

    var caption: String {
        "Repeat your PIN to confirm."
    }

    var textFieldTitle: String {
        "Repeat your PIN code"
    }

    var rightBarButtonImage: UIImage {
        IconProvider.arrowLeft
    }
}
