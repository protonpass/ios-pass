//
//  NavigationBarStyles.swift
//  ProtonCore-Settings - Created on 12.11.2020.
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

public struct NavigationBarStyles {
    public static let `default` = Style<UINavigationBar> { _ in }

    public static let sheet = Style<UINavigationBar> {
        $0.isTranslucent = true
        $0.shadowImage = UIImage()
        $0.barTintColor = ColorProvider.BackgroundNorm
    }
}

extension UINavigationBar {
    private static var _style = [String: Style<UINavigationBar>]()

    public var style: Style<UINavigationBar> {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UINavigationBar._style[tmpAddress] ?? NavigationBarStyles.default
        } set {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UINavigationBar._style[tmpAddress] = newValue
            newValue.apply(to: self)
        }
    }
}

extension UINavigationController {
    public convenience init(rootViewController: UIViewController, style: Style<UINavigationBar>) {
        self.init(rootViewController: rootViewController)
        self.navigationBar.style = style
    }
}
