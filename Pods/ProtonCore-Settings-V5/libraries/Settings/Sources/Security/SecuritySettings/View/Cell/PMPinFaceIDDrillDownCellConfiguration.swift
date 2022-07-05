//
//  PMPreviewSelectedConfiguration.swift
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

protocol PMDrillDownCellViewModel {
    var title: String { get }
    var preview: String? { get }
}

public struct PMPinFaceIDDrillDownCellConfiguration: PMCellSuplier {
    let lockReader: LockReader
    let biometryType: BiometryType
    let action: () -> (UIViewController)

    public init(lockReader: LockReader, biometryType: BiometryType, action: @escaping () -> (UIViewController)) {
        self.biometryType = biometryType
        self.lockReader = lockReader
        self.action = action
    }

    public func cell(at indexPath: IndexPath, for tableView: UITableView, in parent: UIViewController) -> UITableViewCell {
        let cell: PMDrillDownCell = tableView.dequeueReusableCell()

        let onTap = { [weak navigationController = parent.navigationController] in
            let viewController = action()
            navigationController?.pushViewController(viewController, animated: true)
        }

        cell.configureCell(vm: self, action: onTap, hasSeparator: true)
        return cell
    }
}

extension PMPinFaceIDDrillDownCellConfiguration: PMDrillDownCellViewModel {
    var title: String {
        ["PIN", biometryProtectionName].filter { !$0.isEmpty }.joined(separator: " & ")
    }

    private var biometryProtectionName: String {
        let bioProtected = lockReader.isBioProtected ? "Biometry" : ""
        return biometryType == .none ? bioProtected : biometryType.technologyName
    }

    var preview: String? {
        lockReader.isProtectionEnabled() ? "On" : "Off"
    }
}

private extension LockReader {
    func isProtectionEnabled() -> Bool {
        isBioProtected || isPinProtected
    }
}
