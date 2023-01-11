//
//  PMSwitchCell.swift
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

protocol PMSwitchCellViewModel {
    var title: String { get }
    var isActive: Bool { get }

    func didChangeValue(to isOn: Bool, completion: @escaping (Bool) -> Void)
}

final class PMSwitchCell: PMSettingsBaseCell {
    lazy var stack = UIStackView(.horizontal, alignment: .center, distribution: .fill, spacing: 20)
    lazy var titleLabel = UILabel(LabelStyles.body)
    lazy var switchElement = UISwitch()
    private var action: (() -> Void)?
    var viewModel: PMSwitchCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.numberOfLines = 0
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(switchElement)
        switchElement.setContentHuggingPriority(1000, for: .horizontal)
        switchElement.onTintColor = ColorProvider.BrandNorm
        switchElement.addTarget(self, action: #selector(toggle), for: .valueChanged)
    }

    @objc private func toggle(sender: UISwitch) {
        sender.isUserInteractionEnabled = false
        viewModel?.didChangeValue(to: sender.isOn, completion: { [weak sender] _ in
            sender?.isOn = self.viewModel?.isActive ?? false
            sender?.isUserInteractionEnabled = true
        })
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        action = nil
        switchElement.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable identifier_name
    func configure(with vm: PMSwitchCellViewModel, hasSeparator: Bool) {
        self.viewModel = vm
        titleLabel.text = vm.title
        switchElement.isOn = vm.isActive
        addSeparatorIfNeeded(hasSeparator)
    }
}
