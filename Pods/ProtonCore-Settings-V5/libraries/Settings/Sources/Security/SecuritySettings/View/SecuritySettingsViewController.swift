//
//  SecuritySettingsViewController.swift
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

import UIKit
import ProtonCore_UIFoundations

public class SecuritySettingsViewController: UITableViewController {
    var viewModel: SecuritySettingsViewModel!
    var router: SettingsSecurityRouter!

    override public func viewDidLoad() {
        super.viewDidLoad()
        viewModel.onLoadFinished = { [weak self] in
            self?.tableView.reloadData()
        }
        addNavigationBarButton()
        tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorProvider.BackgroundNorm
        tableView.rowHeight = UITableView.automaticDimension
        registerTableViewCells()
    }

    private func addNavigationBarButton() {
        navigationItem.leftBarButtonItem = .back(on: self, action: #selector(dissmissViewController))
    }

    @objc private func dissmissViewController() {
        router.popView()
    }

    private func registerTableViewCells() {
        tableView.register(cellType: PMSwitchCell.self)
        tableView.register(cellType: PMDrillDownCell.self)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = viewModel?.pageTitle
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].title
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellSuplier = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = cellSuplier.cell(at: indexPath, for: tableView, in: self)
        return cell
    }
}
