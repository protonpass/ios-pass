//
//  PMAboutConfiguration.swift
//  ProtonCore-Settings - Created on 25.09.2020.
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

public struct PMAboutConfiguration: PMCellSuplier, PMDrillDownCellViewModel {
    let titleKey: String
    let action: PMSettingsAction
    let bundle: Bundle
    let preview: String? = nil

    public init(title: String, action: PMSettingsAction, bundle: Bundle) {
        self.titleKey = title
        self.action = action
        self.bundle = bundle
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMDrillDownCell = tableView.dequeueReusableCell()

        let onTap = { [weak navigationController = parent.navigationController] in
            switch action {
            case .perform(let action):
                action()
            case .navigate(let action):
                let viewController = action()
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
        cell.configureCell(vm: self, action: onTap, hasSeparator: true)
        return cell
    }

    var title: String {
        titleKey.localized(in: bundle)
    }
}

public struct PMAcknowledgementsConfiguration: PMCellSuplier, PMDrillDownCellViewModel {
    let titleKey: String
    let url: URL
    let bundle: Bundle
    let preview: String? = nil

    public init(title: String, url: URL, bundle: Bundle) {
        self.titleKey = title
        self.url = url
        self.bundle = bundle
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMDrillDownCell = tableView.dequeueReusableCell()
        let title = self.title.localized(in: bundle)

        let onTap = { [weak navigationController = parent.navigationController] in
            let viewController = Self.assembleAcknowledgmentsScreen(title: title, url: url)
            navigationController?.pushViewController(viewController, animated: true)
        }

        cell.configureCell(vm: self, action: onTap, hasSeparator: true)
        return cell
    }

    var title: String {
        titleKey.localized(in: bundle)
    }
}
