//
//  MixUnlockContainerView.swift
//  ProtonCore-Settings - Created on 29.10.2020.
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

final class MixUnlockContainerView: UIView {
    private lazy var stackView = UIStackView(.vertical, alignment: .fill, distribution: .fillEqually, spacing: 20)
    private lazy var pinAligningStack = UIStackView(.horizontal, alignment: .bottom, distribution: .fill)
    private lazy var bioAligningStack = UIStackView(.horizontal, alignment: .center, distribution: .fill)

    private lazy var bioUnlockView = SecondaryBioUnlockView(viewModel: bioViewModel)
    private lazy var pinUnlockView = PrimaryPinUnlockView(viewModel: pinViewModel)

    private let bioViewModel: BiometricUnlockViewModel
    private let pinViewModel: PinUnlockViewModel

    init(bioViewModel: BiometricUnlockViewModel, pinViewModel: PinUnlockViewModel) {
        self.bioViewModel = bioViewModel
        self.pinViewModel = pinViewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContents() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9)
        ])

        addPinProtectionView()
        addBioProtectionView()
    }

    private func addPinProtectionView() {
        stackView.addArrangedSubview(pinAligningStack)
        pinAligningStack.addArrangedSubview(pinUnlockView)
        pinUnlockView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pinUnlockView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }

    private func addBioProtectionView() {
        stackView.addArrangedSubview(bioAligningStack)
        bioAligningStack.addArrangedSubview(bioUnlockView)
    }
}
