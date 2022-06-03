//
//  PMSystemSettingConfiguration.swift
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

public struct PMSystemSettingConfiguration: PMCellSuplier {
    let title: String?
    let description: String?
    let buttonText: String?
    let action: PMSettingsAction
    let bundle: Bundle

    public init(title: String?, description: String?, buttonText: String?, action: PMSettingsAction, bundle: Bundle) {
        self.title = title
        self.description = description
        self.buttonText = buttonText
        self.action = action
        self.bundle = bundle
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMSystemSettingCell = tableView.dequeueReusableCell()
        cell.configureCell(with: self, navigationController: parent.navigationController, hasSeparator: true)
        return cell
    }
}
