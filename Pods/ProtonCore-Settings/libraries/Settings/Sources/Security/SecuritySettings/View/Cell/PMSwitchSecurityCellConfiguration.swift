//
//  PMSwitchSecurityCellConfiguration.swift
//  ProtonCore-Settings - Created on 05.10.2020.
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

public struct PMSwitchSecurityCellConfiguration: PMCellSuplier {
    let title: String
    let switcher: PMSwitcher
    let bundle: Bundle

    public init(title: String, switcher: PMSwitcher, bundle: Bundle = PMSettings.bundle) {
        self.title = title
        self.switcher = switcher
        self.bundle = bundle
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMSwitchCell = tableView.dequeueReusableCell()
        cell.configure(with: self, hasSeparator: true)
        return cell
    }
}

extension PMSwitchSecurityCellConfiguration: PMSwitchCellViewModel {
    var isActive: Bool {
        switcher.isActive
    }

    func didChangeValue(to isOn: Bool, completion: @escaping (Bool) -> Void) {
        switcher.changeValue(to: isOn, success: completion)
    }
}
