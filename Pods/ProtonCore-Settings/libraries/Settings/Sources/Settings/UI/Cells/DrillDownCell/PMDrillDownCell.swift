//
//  PMDrillDownCell.swift
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

final class PMDrillDownCell: PMSettingsBaseCell {
    lazy var stack = UIStackView(.horizontal, alignment: .center, distribution: .fill, spacing: 20)
    lazy var drillDownStack = UIStackView(.horizontal, alignment: .center, distribution: .fill, spacing: 8)
    lazy var titleLabel = UILabel(LabelStyles.body)
    lazy var previewLabel = UILabel(LabelStyles.bodyWeak)
    lazy var arrow = UIImageView.arrowRight

    private var action: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 0
        previewLabel.numberOfLines = 0

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(drillDownStack)
        drillDownStack.addArrangedSubview(previewLabel)
        drillDownStack.addArrangedSubview(arrow)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        contentView.addGestureRecognizer(tap)

        previewLabel.setContentCompressionResistancePriority(1000, for: .horizontal)
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        previewLabel.text = nil
        action = nil
    }

    @objc private func onTap() {
        action?()
    }

    // swiftlint:disable identifier_name
    func configureCell(vm: PMDrillDownCellViewModel, action: @escaping () -> Void, hasSeparator: Bool) {
        self.action = action
        titleLabel.text = vm.title
        previewLabel.text = vm.preview
        addSeparatorIfNeeded(hasSeparator)
    }
}

private extension UIImageView {
    static var arrowRight: UIImageView {
        let arrow = UIImageView(frame: .zero)
        arrow.image = IconProvider.arrowRight
        arrow.setSizeContraint(height: 20, width: 20)
        arrow.tintColor = ColorProvider.IconHint
        return arrow
    }
}
