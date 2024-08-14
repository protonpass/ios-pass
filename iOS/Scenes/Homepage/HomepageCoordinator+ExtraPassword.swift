//
// HomepageCoordinator+ExtraPassword.swift
// Proton Pass - Created on 05/06/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Macro
import SwiftUI

extension HomepageCoordinator {
    func beginEnableExtraPasswordFlow() {
        let view = ExtraPasswordSheet { [weak self] in
            guard let self else { return }
            presentEnableExtraPasswordView()
        }
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.custom(380),
                                     parentViewController: rootViewController)
        present(viewController)
    }
}

private extension HomepageCoordinator {
    func presentEnableExtraPasswordView() {
        let onFailure: () -> Void = { [weak self] in
            guard let self else { return }
            handleFailedLocalAuthentication(nil)
        }
        let onSuccess: () -> Void = { [weak self] in
            guard let self else { return }
            bannerManager.displayBottomInfoMessage(#localized("Extra password set"))
        }
        let view = EnableExtraPasswordView(onProtonPasswordVerificationFailure: onFailure,
                                           onExtraPasswordEnabled: onSuccess)
        present(view)
    }
}
