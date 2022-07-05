//
//  PasswordConfigurationViewController.swift
//  ProtonCore-Settings - Created on 02.10.2020.
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

final class PasswordConfigurationViewController: UIViewController {
    lazy var textField = makeTextField()
    lazy var rightButton = makeRightButton()

    var viewModel: PasswordConfigurationViewModel!
    var router: SecurityPasswordRouter!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        setupNavigationBar()
        setupTextField()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = viewModel.title
        textField.focusOnTextField()
        textField.setCaption(viewModel.caption)
        rightButton.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel?.viewWillDissapear()
    }

    private func setupNavigationBar() {
        let image = viewModel.rightBarButtonImage
        navigationItem.leftBarButtonItem = .button(on: self, action: #selector(dissmissTapped), image: image)
        navigationItem.rightBarButtonItem = rightButton
    }

    private func setupTextField() {
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            textField.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 26)
        ])
        textField.delegate = self
    }

    @objc private func dissmissTapped() {
        viewModel?.withdrawFromScreen()
    }

    @objc private func advanceButtonTapped() {
        viewModel?.advance()
    }

    func showError(_ error: String) {
        let banner = PMBanner(message: error, style: PMBannerNewStyle.error)
        banner.show(at: .bottom, on: self)
    }
}

extension PasswordConfigurationViewController: SettingsTextFieldDelegate {
    func textField(didChangeText text: String) {
        viewModel?.userInputDidChange(to: text)
    }
}

extension PasswordConfigurationViewController {
    private func makeRightButton() -> UIBarButtonItem {
        let button = UIBarButtonItem(title: viewModel.buttonText, style: .done, target: self, action: #selector(advanceButtonTapped))
        let foregroundColor: UIColor = ColorProvider.BrandLighten20
        button.setTitleTextAttributes([.foregroundColor: foregroundColor,
                                       .font: UIFont.preferredFont(forTextStyle: .headline)], for: .normal)
        button.setTitleTextAttributes([.font: UIFont.preferredFont(forTextStyle: .headline)], for: .highlighted)
        button.setTitleTextAttributes([.font: UIFont.preferredFont(forTextStyle: .headline)], for: .disabled)
        return button
    }

    private func makeTextField() -> PMSettingsPasswordTextField {
        let textField = PMSettingsPasswordTextField(type: .numberPad)
        textField.addRule(rule: NSRegularExpression(for: "^[0-9]{0,21}$"), error: "Invalid password")
        textField.setTitle(viewModel.textFieldTitle)
        return textField
    }
}
