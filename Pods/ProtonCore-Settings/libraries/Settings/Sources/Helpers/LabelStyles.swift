//
//  LabelStyles.swift
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

import UIKit
import ProtonCore_UIFoundations

public struct LabelStyles {
    static let `default` = Style<UILabel> { _ in }

    static let headline = Style<UILabel> {
        $0.textColor = ColorProvider.TextNorm
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.adjustsFontForContentSizeCategory = true
    }

    static let body = Style<UILabel> {
        $0.textColor = ColorProvider.TextNorm
        $0.font = PMFontStyles.body1
        $0.adjustsFontForContentSizeCategory = true
    }

    static let body2 = Style<UILabel> {
        $0.textColor = ColorProvider.TextWeak
        $0.font = PMFontStyles.body2
        $0.adjustsFontForContentSizeCategory = true
    }

    static let caption = Style<UILabel> {
        $0.textColor = ColorProvider.TextNorm
        $0.font = PMFontStyles.caption
        $0.adjustsFontForContentSizeCategory = true
    }

    static let captionSemiBold = Style<UILabel> {
        $0.textColor = ColorProvider.TextNorm
        $0.font = PMFontStyles.captionSemiBold
        $0.adjustsFontForContentSizeCategory = true
    }

    static let footnote = Style<UILabel> {
        $0.textColor = ColorProvider.TextWeak
        $0.font = .preferredFont(forTextStyle: .body)
    }
}

public extension LabelStyles {
    static let bodyWeak = Style<UILabel> {
        $0.textColor = ColorProvider.TextWeak
        $0.font = .preferredFont(forTextStyle: .body)
        $0.adjustsFontForContentSizeCategory = true
    }
}

public extension UILabel {
    private static var _style = [String: Style<UILabel>]()

    var style: Style<UILabel> {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UILabel._style[tmpAddress] ?? LabelStyles.default
        } set {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UILabel._style[tmpAddress] = newValue
            newValue.apply(to: self)
        }
    }
}

public extension UILabel {
    convenience init(_ style: Style<UILabel>) {
        self.init(frame: .zero)
        self.style = style
    }
}
