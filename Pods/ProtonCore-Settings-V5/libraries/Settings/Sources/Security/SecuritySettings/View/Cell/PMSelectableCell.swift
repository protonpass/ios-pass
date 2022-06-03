//
//  PMSelectableCell.swift
//  ProtonCore-Settings - Created on 04.10.2020.
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

class PMSelectableCell: PMSettingsBaseCell {
    private var action: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        tintColor = ColorProvider.BrandLighten20
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        contentView.addGestureRecognizer(tap)
    }

    @objc private func onTapped() {
        action?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        action = nil
        accessoryType = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(with model: PMSelectableConfiguration, hasSeparator: Bool, isSelected: Bool) {
        self.action = model.action
        textLabel?.text = model.title
        textLabel?.textColor = isSelected ? ColorProvider.TextNorm : ColorProvider.FloatyText
        accessoryType = isSelected ? .checkmark : .none
        addSeparatorIfNeeded(hasSeparator)
    }
}
