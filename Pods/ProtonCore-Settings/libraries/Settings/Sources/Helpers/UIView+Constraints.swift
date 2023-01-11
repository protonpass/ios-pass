//
//  UIView+Constraints.swift
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

public extension UIView {
    typealias Constraints = (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?, leading: NSLayoutConstraint?, trailing: NSLayoutConstraint?)

    @discardableResult
    func fillSuperviewWithConstraints(margin: CGFloat = 0) -> Constraints? {
        fillSuperviewWithConstraints(top: margin, bottom: -margin, leading: margin, trailing: -margin)
    }

    @discardableResult
    func fillSuperviewWithConstraints(vertical: CGFloat = 0, horizontal: CGFloat = 0) -> Constraints? {
        fillSuperviewWithConstraints(top: vertical, bottom: -vertical, leading: horizontal, trailing: -horizontal)
    }

    @discardableResult
    func fillSuperviewWithConstraints(top: CGFloat? = 0, bottom: CGFloat? = 0, leading: CGFloat? = 0, trailing: CGFloat? = 0) -> Constraints? {
        guard let superview = superview else { return nil }
        translatesAutoresizingMaskIntoConstraints = false

        let top: NSLayoutConstraint? = top != nil ? topAnchor.constraint(equalTo: superview.topAnchor, constant: top!) : nil
        let bottom: NSLayoutConstraint? = bottom != nil ? bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: bottom!) : nil
        let leading: NSLayoutConstraint? = leading != nil ? leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: leading!) : nil
        let trailing: NSLayoutConstraint? = trailing != nil ?  trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: trailing!) : nil
        NSLayoutConstraint.activate([top, bottom, leading, trailing].compactMap { $0 })
        return (top, bottom, leading, trailing)
    }

    func centerXInSuperview(constant: CGFloat = 0) {
        guard let anchor = superview?.centerXAnchor else { return }
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }

    func centerYInSuperview(constant: CGFloat = 0) {
        guard let anchor = superview?.centerYAnchor else { return }
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }

    func centerInSuperview() {
        centerXInSuperview()
        centerYInSuperview()
    }

    @discardableResult
    func setContraintsWithConstraints(height: CGFloat?, width: CGFloat?) -> (height: NSLayoutConstraint?, width: NSLayoutConstraint?) {
        self.translatesAutoresizingMaskIntoConstraints = false
        var (heightConstraint, widthConstraint): (NSLayoutConstraint?, NSLayoutConstraint?)
        if let height = height {
            heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
            heightConstraint?.isActive = true
        }
        if let width = width {
            widthConstraint = widthAnchor.constraint(equalToConstant: width)
            widthConstraint?.isActive = true
        }
        return (heightConstraint, widthConstraint)
    }
}
