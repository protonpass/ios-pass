//
//  PMHostCell.swift
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

class PMHostCell: UITableViewCell, PMContainerReloader, Reusable {
    private weak var parentViewController: UIViewController?
    private weak var childViewController: PMContainerReloading?
    private weak var tableView: UITableView?
    private var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        remove(child: childViewController)

        childViewController = nil
        parentViewController = nil
        tableView = nil
        indexPath = nil
    }

    func configureCell(with child: UIViewController, parent: UIViewController, tableView: UITableView, indexPath: IndexPath) {
        parentViewController = parent
        childViewController = child as? PMContainerReloading
        childViewController?.containerReloader = self
        self.tableView = tableView
        self.indexPath = indexPath

        display(child: child, on: parent)
    }

    func display(child: UIViewController, on parent: UIViewController) {
        child.view.frame = contentView.bounds
        contentView.addSubview(child.view)
        parent.addChild(child)
        child.didMove(toParent: parent)

        let constraints = child.view.fillSuperviewWithConstraints()
        constraints?.top?.priority = UILayoutPriority(999)
        constraints?.bottom?.priority = UILayoutPriority(999)
    }

    func remove(child: UIViewController?) {
        child?.willMove(toParent: nil)
        child?.removeFromParent()
        child?.view.removeFromSuperview()
    }

    func reload() {
        guard let indexPath = indexPath else { return }
        self.tableView?.performBatchUpdates({
            tableView?.reloadRows(at: [indexPath], with: .none)
        }, completion: nil)
    }
}

private extension PMHostCell {
    func makeStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }
}
