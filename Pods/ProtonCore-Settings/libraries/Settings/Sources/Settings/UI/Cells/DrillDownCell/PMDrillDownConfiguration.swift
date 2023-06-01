//
//  PMTitleValueConfiguration.swift
//  ProtonCore-Settings - Created on 10.05.2023.
//
//  Copyright (c) 2023 Proton AG
//
//  This file is part of ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import UIKit

public class PMDrillDownConfiguration: PMCellSuplier {
    private let viewModel: PMDrillDownCellViewModel
    private let viewControllerFactory: () -> (UIViewController)

    public init(viewModel: PMDrillDownCellViewModel, viewControllerFactory: @escaping () -> (UIViewController)) {
        self.viewModel = viewModel
        self.viewControllerFactory = viewControllerFactory
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMDrillDownCell = tableView.dequeueReusableCell()
        let action = { [weak self, weak parent] in
            guard let self = self else {
                return
            }
            let viewController = self.viewControllerFactory()
            parent?.navigationController?.pushViewController(viewController, animated: true)
        }
        cell.configureCell(vm: viewModel, action: action, hasSeparator: true)
        return cell
    }
}
