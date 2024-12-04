//
// HomepageCoordinator+DeepLinks.swift
// Proton Pass - Created on 29/01/2024.
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

import DesignSystem
import SwiftUI

extension HomepageCoordinator {
    func totpDeepLink(totpUri: String) {
        let viewModel = TotpLoginsViewModel(totpUri: totpUri)
        let view = TotpLoginsView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.large, parentViewController: rootViewController)

        present(viewController)
    }

    func presentCreateEditLoginView(mode: ItemMode) {
        do {
            let viewModel = try CreateEditLoginViewModel(mode: mode,
                                                         upgradeChecker: upgradeChecker,
                                                         vaults: appContentManager.getAllVaults())
            viewModel.delegate = self
            let view = CreateEditLoginView(viewModel: viewModel)
            present(view)
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }
}
