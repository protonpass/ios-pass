//
//  PMFontStyles.swift
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

final class PMFontStyles {
    static let body1SemiBold: UIFont = {
        return UIFont.preferredFont(forTextStyle: .headline)
    }()

    static let body1: UIFont = {
        return UIFont.preferredFont(forTextStyle: .body)
    }()

    static let body2SemiBold: UIFont = {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        return fontMetrics.scaledFont(for: font)
    }()

    static let body2: UIFont = {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }()

    static let captionSemiBold: UIFont = {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .footnote)
        return fontMetrics.scaledFont(for: font)
    }()

    static let caption: UIFont = {
        return UIFont.preferredFont(forTextStyle: .footnote)
    }()

    static let overlineSemiBold: UIFont = {
        let font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let fontMetrics = UIFontMetrics(forTextStyle: .caption2)
        return fontMetrics.scaledFont(for: font)
    }()

    static let overline: UIFont = {
        return UIFont.preferredFont(forTextStyle: .caption2)
    }()
}
