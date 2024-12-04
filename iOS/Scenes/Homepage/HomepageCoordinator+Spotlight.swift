//
// HomepageCoordinator+Spotlight.swift
// Proton Pass - Created on 05/02/2024.
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
import Entities
import SwiftUI

extension HomepageCoordinator {
    func presentEditSpotlightSearchableContentView() {
        let currentValue = getUserPreferences().spotlightSearchableContent
        let view = EditSpotlightSearchableContentView(selection: currentValue) { [weak self] newValue in
            guard let self else { return }
            updateUserPreferences(\.spotlightSearchableContent, value: newValue)
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.short.value) * SpotlightSearchableContent.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentEditSpotlightSearchableVaultsView() {
        let currentValue = getUserPreferences().spotlightSearchableVaults
        let view = EditSpotlightSearchableVaultsView(selection: currentValue) { [weak self] newValue in
            guard let self else { return }
            updateUserPreferences(\.spotlightSearchableVaults, value: newValue)
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.short.value) * SpotlightSearchableVaults.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func presentEditSpotlightVaultsView() {
        let viewController = UIHostingController(rootView: EditSpotlightVaultsView())
        let allVaults = appContentManager.getAllSharesLinkToVault()
        let customHeight = Int(OptionRowHeight.short.value) * allVaults.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }
}
