//
//  BioUnlockContainerView.swift
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

final class BioUnlockContainerView: UIView {

    private lazy var bioUnlockView = PrimaryBioUnlockView(viewModel: viewModel)

    private let viewModel: BiometricUnlockViewModel

    init(viewModel: BiometricUnlockViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        addSubview(bioUnlockView)
        bioUnlockView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bioUnlockView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            bioUnlockView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            bioUnlockView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            bioUnlockView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
    }
}
