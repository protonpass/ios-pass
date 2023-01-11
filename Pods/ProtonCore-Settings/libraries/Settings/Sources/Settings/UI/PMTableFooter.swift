//
//  PMTableFooter.swift
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
import ProtonCore_UIFoundations

class PMTableFooter: UIView {
    let label = UILabel(LabelStyles.caption)

    override init(frame: CGRect) {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 100)))
        addSubview(label)
        label.fillSuperviewWithConstraints(vertical: 30, horizontal: 24)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = ColorProvider.TextHint
        label.setContentCompressionResistancePriority(1000, for: .vertical)
    }

    func setTitle(_ title: String) {
        label.text = title
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
