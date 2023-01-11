//
//  PMAutolockDrillDownCellConfiguration.swift
//  ProtonCore-Settings - Created on 16.11.2020.
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

public struct PMAutolockSelectionCellConfiguration: PMCellSuplier {
    let autoLocker: AutoLocker
    let router: SettingsSecurityRouter

    public init(autoLocker: AutoLocker, router: SettingsSecurityRouter) {
        self.autoLocker = autoLocker
        self.router = router
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMDrillDownCell = tableView.dequeueReusableCell()

        let onTap = { [weak navigationController = parent.navigationController] in
            var sheet: PMActionSheet!
            let header = PMActionSheetHeaderView(title: "Auto-Lock Timeout", subtitle: nil, leftItem: nil, rightItem: nil)

            // selectable rows
            let items = [LockTime.never, .always, .every(minutes: 1), .every(minutes: 2), .every(minutes: 5), .every(minutes: 10), .every(minutes: 15), .every(minutes: 30), .every(minutes: 60)]
            .map { timeout in
                PMActionSheetPlainItem(title: timeout.title, icon: nil, isOn: self.autoLocker.autolockerTimeout == timeout) { [unowned sheet, unowned autoLocker, unowned router] _ in
                    autoLocker.setAutolockerTimeout(timeout)
                    router.refreshSections?()
                    sheet?.dismiss(animated: true)
                }
            }
            let itemsGroup = PMActionSheetItemGroup(items: items, style: .clickable)

            // cancel
            let cancel = PMActionSheetPlainItem(title: "Cancel", icon: nil, textColor: ColorProvider.TextWeak, alignment: .center, hasSeparator: false, handler: nil)
            let cancelGroup = PMActionSheetItemGroup(items: [cancel], style: .clickable)

            // sheet
            sheet = PMActionSheet(headerView: header, itemGroups: [itemsGroup, cancelGroup])
            if let presenter = navigationController {
                sheet.presentAt(presenter, animated: true)
            }
        }

        cell.configureCell(vm: self, action: onTap, hasSeparator: true)
        return cell
    }
}

extension PMAutolockSelectionCellConfiguration: PMDrillDownCellViewModel {
    var title: String {
        "Auto-Locker"
    }

    var preview: String? {
        return autoLocker.autolockerTimeout.title
    }
}
