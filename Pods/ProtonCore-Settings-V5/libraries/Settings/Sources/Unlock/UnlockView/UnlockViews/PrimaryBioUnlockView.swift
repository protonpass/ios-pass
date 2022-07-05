//
//  PrimaryBioUnlockView.swift
//  ProtonCore-Settings - Created on 01.11.2020.
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

final class PrimaryBioUnlockView: UIView {
    private lazy var stack = UIStackView(.vertical, alignment: .center, distribution: .fill, spacing: 20)
    private lazy var bioAligningstack = UIStackView(.horizontal, alignment: .center, distribution: .fill)
    private lazy var bioProtectionImage = CircularBioImage()
    private lazy var bioProtectionButton = UIButton(ButtonStyles.secondary)

    private let viewModel: BiometricUnlockViewModel

    init(viewModel: BiometricUnlockViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContents() {
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])

        addBioImage()
        addBioProtectionButton()
    }

    private func addBioImage() {
        stack.addArrangedSubview(bioAligningstack)

        bioAligningstack.addArrangedSubview(bioProtectionImage)
        NSLayoutConstraint.activate([
            bioProtectionImage.heightAnchor.constraint(equalToConstant: 212),
            bioProtectionImage.widthAnchor.constraint(equalToConstant: 212)
        ])
        bioProtectionImage.setContentCompressionResistancePriority(1000, for: .vertical)
        bioProtectionImage.setupImage(authentication: viewModel.biometryType)
        bioProtectionImage.setupCaption(authentication: viewModel.biometryType)
    }

    private func addBioProtectionButton() {
        stack.addArrangedSubview(bioProtectionButton)
        bioProtectionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bioProtectionButton.heightAnchor.constraint(equalToConstant: 48),
            bioProtectionButton.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.9)
        ])
        bioProtectionButton.style = ButtonStyles.main
        bioProtectionButton.setContentHuggingPriority(1000, for: .vertical)
        bioProtectionButton.setTitle(viewModel.biometryType.buttonText, for: .normal)
        bioProtectionButton.addTarget(self, action: #selector(bioConfirmationTapped), for: .touchUpInside)
    }

    @objc private func bioConfirmationTapped() {
        viewModel.unlockWithBio()
    }
}
