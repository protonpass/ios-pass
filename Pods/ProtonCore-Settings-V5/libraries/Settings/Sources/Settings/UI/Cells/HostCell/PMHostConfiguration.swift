//
//  PMHostConfiguration.swift
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

public protocol PMContainerReloader: AnyObject {
    func reload()
}

public protocol PMContainerReloading where Self: UIViewController {
    var containerReloader: PMContainerReloader? { get set }
}

public struct PMHostConfiguration: PMCellSuplier {
    let viewController: PMContainerReloading

    public init(viewController: PMContainerReloading) {
        self.viewController = viewController
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMHostCell = tableView.dequeueReusableCell()
        cell.configureCell(with: viewController, parent: parent, tableView: tableView, indexPath: indexPath)
        return cell
    }
}
