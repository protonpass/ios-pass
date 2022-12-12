//
//  PMSettingsViewController.swift
//  ProtonCore-Settings - Created on 23.09.2020.
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

public class PMSettingsViewController: UITableViewController {
    public var viewModel: PMSettingsViewModelProtocol!
    public var leftButton: PMSettingsLeftBarButton?

    override public func viewDidLoad() {
        super.viewDidLoad()

        addNavigationBarButton()
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorProvider.BackgroundNorm
        registerTableViewCells()
        if let footerText = viewModel.footer {
            let footerView = PMTableFooter()
            footerView.setTitle(footerText)
            tableView.tableFooterView = footerView
        }
    }

    private func addNavigationBarButton() {
        if let leftButton = leftButton {
            navigationItem.leftBarButtonItem = .button(on: self, action: #selector(alternativeAction), image: leftButton.image)
        } else {
            navigationItem.leftBarButtonItem = .close(on: self, action: #selector(dissmissViewController))
        }
    }

    @objc private func dissmissViewController() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func alternativeAction() {
        leftButton?.action()
    }

    private func registerTableViewCells() {
        tableView.register(cellType: PMSystemSettingCell.self)
        tableView.register(cellType: PMHostCell.self)
        tableView.register(cellType: PMSelectableCell.self)
        tableView.register(cellType: PMDrillDownCell.self)
        tableView.register(cellType: PMSwitchCell.self)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = viewModel?.pageTitle
        tableView.reloadData()
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].title
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellSuplier = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = cellSuplier.cell(at: indexPath, for: tableView, in: self)
        return cell
    }
}

extension UITableView {
    func isLastInSection(for indexPath: IndexPath) -> Bool {
        let rowsInSection = numberOfRows(inSection: indexPath.section)
        let lastRowInSectionIndex = rowsInSection > 0 ? rowsInSection - 1 : 0

        return indexPath.row == lastRowInSectionIndex
    }
}
