//
//  ButtonStyles.swift
//  ProtonCore-Settings - Created on 27.10.2020.
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

public struct ButtonStyles {
    public static let `default` = Style<UIButton> { _ in }

    public static let main = Style<UIButton> {
        $0.titleLabel?.style = LabelStyles.body

        $0.setTitleColor(.white, for: .normal)
        $0.setBackground(ColorProvider.BrandNorm, for: .normal)

        $0.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        $0.setBackground(ColorProvider.BrandNorm.withAlphaComponent(0.5), for: .highlighted)

        $0.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        $0.setBackground(ColorProvider.BrandNorm.withAlphaComponent(0.5), for: .disabled)

        $0.layer.cornerRadius = 8.0
        $0.layer.masksToBounds = true
    }

    public static let secondary = Style<UIButton> {
        $0.titleLabel?.style = LabelStyles.body
        $0.setTitleColor(.white, for: .normal)
        $0.setTitleColor(ColorProvider.TextWeak, for: .normal)
        $0.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        $0.layer.cornerRadius = 8.0
    }
}

public extension UIButton {
    private static var _style = [String: Style<UIButton>]()

    var style: Style<UIButton> {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIButton._style[tmpAddress] ?? ButtonStyles.default
        } set {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIButton._style[tmpAddress] = newValue
            newValue.apply(to: self)
        }
    }
}

public extension UIButton {
    convenience init(_ style: Style<UIButton>) {
        self.init(frame: .zero)
        self.style = style
    }
}

extension UIColor {
    func createOnePixelImage() -> UIImage? {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIButton {
    func setBackground(_ color: UIColor, for state: UIControl.State) {
        setBackgroundImage(color.createOnePixelImage(), for: state)
    }
}
