//
//  PMSystemSettingCell.swift
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
import ProtonCore_UIFoundations

public enum PMSettingsAction {
    case perform(() -> Void)
    case navigate(() -> (UIViewController))
}

class PMSystemSettingCell: PMSettingsBaseCell {
    lazy var stack = UIStackView(.vertical, alignment: .leading, distribution: .fill, spacing: 8)
    lazy var titleLabel = UILabel.makeTitleLabel()
    lazy var descriptionLabel = UILabel.makeDescriptionLabel()
    lazy var button = makeButton()
    weak var navigationController: UINavigationController?

    private var action: PMSettingsAction?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(stack)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descriptionLabel)
        stack.addArrangedSubview(button)
        stack.fillSuperviewWithConstraints(margin: 16)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        descriptionLabel.text = nil
        button.setTitle(nil, for: .normal)
    }

    @objc private func onButtonPressed() {
        guard let actionType = action else { return }
        switch actionType {
        case .perform(let action):
            action()
        case .navigate(let action):
            let viewController = action()
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func configureCell(with model: PMSystemSettingConfiguration, navigationController: UINavigationController?, hasSeparator: Bool) {
        self.navigationController = navigationController
        titleLabel.text = model.title?.localized(in: model.bundle)
        descriptionLabel.text = model.description?.localized(in: model.bundle)
        button.setTitle(model.buttonText?.localized(in: model.bundle), for: .normal)
        action = model.action
        addSeparatorIfNeeded(hasSeparator)
    }
}

private extension PMSystemSettingCell {
    func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
        button.tintColor = ColorProvider.BrandLighten20
        button.setImage(IconProvider.fileArrowIn, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: 8)
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        button.titleLabel?.style = LabelStyles.caption
        return button
    }
}

extension UILabel {
    class func makeTitleLabel() -> UILabel {
        let label = UILabel(LabelStyles.body)
        label.numberOfLines = 0
        return label
    }

    class func makeDescriptionLabel() -> UILabel {
        let label = UILabel(LabelStyles.body2)
        label.numberOfLines = 0
        return label
    }
}
