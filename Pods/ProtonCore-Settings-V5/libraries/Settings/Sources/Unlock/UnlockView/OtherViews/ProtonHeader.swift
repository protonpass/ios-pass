//
//  ProtonHeader.swift
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

final class ProtonHeader: UIView {
    lazy var stack = UIStackView(.vertical, alignment: .center, distribution: .fill, spacing: 8)
    lazy var imageView = UIImageView()
    lazy var subtitleLabel: UILabel = makeSubtitleLabel()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
        stack.addArrangedSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 22),
            imageView.widthAnchor.constraint(equalToConstant: 150)
        ])
        stack.addArrangedSubview(subtitleLabel)
    }

    private func makeSubtitleLabel() -> UILabel {
        let label = UILabel()
        label.style = LabelStyles.bodyWeak
        label.numberOfLines = 3
        label.textAlignment = .center
        label.setContentHuggingPriority(1000, for: .vertical)
        label.setContentCompressionResistancePriority(1000, for: .vertical)
        return label
    }
}

extension ProtonHeader {
    func setupHeader(image: UIImage?, subtitle: String?) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        imageView.tintColor = ColorProvider.TextNorm
        subtitleLabel.text = subtitle
    }
}
