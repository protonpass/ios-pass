//
//  Reusable.swift
//  ProtonCore-Settings - Created on 28.09.2020.
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

import ProtonCore_UIFoundations

protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

import UIKit
// MARK: - UITableView Extensions
extension UITableView {
    final func  register<T: UITableViewHeaderFooterView & Reusable>(cellType: T.Type) {
        register(cellType.self, forHeaderFooterViewReuseIdentifier: cellType.reuseIdentifier)
    }

    final func  register<T: UITableViewCell & Reusable>(cellType: T.Type) {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }
}

extension UITableView {
    final func dequeueReusableCell<T: UITableViewHeaderFooterView & Reusable>() -> T {
        guard let cell = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Failed to dequeue reusable cell with identifier '\(T.reuseIdentifier)'.")
        }
        return cell
    }

    final func dequeueReusableCell<T: UITableViewCell & Reusable>() -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Failed to dequeue reusable cell with identifier '\(T.reuseIdentifier)'.")
        }
        return cell
    }
}
