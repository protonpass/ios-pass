//
//  PrimaryPinUnlockView.swift
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

final class PrimaryPinUnlockView: UIView {
    private lazy var stack = UIStackView(.vertical, alignment: .fill, distribution: .fill, spacing: 48)
    private lazy var textField = PMSettingsPasswordTextField(type: .numberPad)
    private lazy var confirmationButton = makeConfirmationButton()

    private(set) var viewModel: PinUnlockViewModel

    init(viewModel: PinUnlockViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        translatesAutoresizingMaskIntoConstraints = false
        setupContents()
        textField.delegate = self
        self.viewModel.onPinUnlockFailure = { [weak self] in
            self?.textField.setTemporaryError("Wrong PIN")
            self?.confirmationButton.isEnabled = false
        }
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

        addTextFieldView()
        addConfirmationButton()
    }

    private func addTextFieldView() {
        stack.addArrangedSubview(textField)
        textField.setTitle("Enter your PIN code")
    }

    private func addConfirmationButton() {
        stack.addArrangedSubview(confirmationButton)
        confirmationButton.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            confirmationButton.heightAnchor.constraint(equalToConstant: 48),
            confirmationButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ]
        constraints.first?.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate(constraints)
        confirmationButton.setContentCompressionResistancePriority(1000, for: .vertical)
        confirmationButton.setTitle("Confirm", for: .normal)
    }

    private func makeConfirmationButton() -> UIButton {
        let button = UIButton(ButtonStyles.main)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(pinConfirmationTapped), for: .touchUpInside)
        return button
    }

    @objc private func pinConfirmationTapped() {
        guard let pin = textField.text,
              !pin.isEmpty else {
            return
        }
        viewModel.unlockWithPin(pin)
    }
}

extension PrimaryPinUnlockView {
    func showKeyboard() {
        textField.focusOnTextField()
    }
}

extension PrimaryPinUnlockView: SettingsTextFieldDelegate {
    func textField(didChangeText text: String) {
        confirmationButton.isEnabled = !text.isEmpty
    }
}
