//
//  InitialPasswordConfigurationViewModel.swift
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

import ProtonCore_UIFoundations

final class InitialPasswordConfigurationViewModel: PasswordConfigurationViewModel {
    private let router: SecurityPasswordRouter
    private let passwordSelector: PasswordSelector

    var rightNavigationButtonEnabled: Observer<Bool>?
    private var couldFinishStepSuccessfully = false

    init(passwordSelector: PasswordSelector, router: SecurityPasswordRouter) {
        self.router = router
        self.passwordSelector = passwordSelector
    }

    func userInputDidChange(to text: String) {
        do {
            try passwordSelector.setInitialPassword(to: text)
            rightNavigationButtonEnabled?(true)
        } catch {
            rightNavigationButtonEnabled?(false)
        }
    }

    func withdrawFromScreen() {
        router.withdraw()
    }

    func advance() {
        couldFinishStepSuccessfully = true
        router.advance()
    }

    func viewWillDissapear() {
        guard !couldFinishStepSuccessfully else { return }
        router.finishWithSuccess(false)
    }

    var title: String {
        "Use PIN code"
    }

    var buttonText: String {
        "Next"
    }

    var caption: String {
        "Enter a PIN code with min 4 characters and max 21 characters."
    }

    var textFieldTitle: String {
        "Set your PIN code"
    }

    var rightBarButtonImage: UIImage {
        IconProvider.crossSmall
    }
}
