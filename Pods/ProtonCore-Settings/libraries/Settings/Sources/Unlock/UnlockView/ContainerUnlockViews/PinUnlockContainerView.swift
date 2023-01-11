//
//  PinUnlockContainerView.swift
//  ProtonCore-Settings - Created on 28.10.2020.
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

final class PinUnlockContainerView: UIView {
    private lazy var pinAligningStack = UIStackView(.horizontal, alignment: .top, distribution: .fill)
    private lazy var pinUnlockView = PrimaryPinUnlockView(viewModel: pinViewModel)

    private let pinViewModel: PinUnlockViewModel

    init(pinViewModel: PinUnlockViewModel) {
        self.pinViewModel = pinViewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContents() {
        addSubview(pinAligningStack)
        pinAligningStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pinAligningStack.topAnchor.constraint(equalTo: self.topAnchor, constant: 40),
            pinAligningStack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            pinAligningStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            pinAligningStack.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9)
        ])

        pinAligningStack.addArrangedSubview(pinUnlockView)
    }
}

extension PinUnlockContainerView {
    func showKeyboard() {
        pinUnlockView.showKeyboard()
    }
}
