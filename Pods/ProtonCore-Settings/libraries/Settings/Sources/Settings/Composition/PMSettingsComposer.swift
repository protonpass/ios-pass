//
//  PMSettingsComposer.swift
//  ProtonCore-Settings - Created on 24.09.2020.
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

/// Type as NameSpace that helps building `PMSettingsViewController`
public final class PMSettingsComposer {
    private init() { }

    /// Creates`PMSettingsViewController`
    /// - Parameters:
    ///   - sections: Each of the sections of `PMSettingsViewController`
    ///   - leftBarButtonAction: Image and action of the left navigation bar button, the default image
    ///   and action are `X` and close `PMSettingsViewController` respectivelly.
    ///   - withinNavigationController: Bool that indicates if `PMSettingsViewController` should be wrapped
    ///   by a `UINAvigationController` in case pushing has more meaning than presenting it.
    /// - Returns: `UIViewController` that either is or contains a `PMSettingsViewController`
    /// depending on `withinNavigationController` parameter.
    public static func assemble(sections: [PMSettingsSectionViewModel],
                                leftBarButtonAction: PMSettingsLeftBarButton? = nil,
                                withinNavigationController: Bool = true) -> UIViewController {

        let viewController = PMSettingsViewController()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let viewModel = PMSettingsViewModel(sections: sections, version: version)
        viewController.viewModel = viewModel
        viewController.leftButton = leftBarButtonAction

        if withinNavigationController {
            return DarkModeAwareNavigationViewController(rootViewController: viewController, style: NavigationBarStyles.sheet)
        } else {
            return viewController
        }
    }
}

public final class  SettingsSectionComposer {
    public static func assemble(title: KeyInBundle, sections: [PMCellSuplier]) -> PMSettingsSectionViewModel {
        return PMSettingsSectionViewModel(title: title, rows: sections)
    }
}

public struct PMSettingsLeftBarButton {
    public let image: UIImage?
    public let action: () -> Void

    public init(image: UIImage?, action: @escaping () -> Void) {
        self.image = image
        self.action = action
    }
}
