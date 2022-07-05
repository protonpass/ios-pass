//
//  PMSettingsPasswordTextField.swift
//  ProtonCore-Settings - Created on 03.10.2020.
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

public protocol SettingsTextFieldDelegate: AnyObject {
    func textField(didChangeText text: String)
}

public final class PMSettingsPasswordTextField: UIView, UITextFieldDelegate {
    let mainStack = UIStackView(.vertical, alignment: .fill, distribution: .fill, spacing: 8)
    let secondaryStack = UIStackView(.vertical, alignment: .fill, distribution: .fill, spacing: 4)

    let titleLabel = makeTitleLabel()

    let inputContainerView = makeInputContainerdView()
    let textFieldStack = UIStackView(.horizontal, alignment: .center, distribution: .fill, spacing: 8)
    let textField = makeTextField()
    let isSecureButton = makeClearTextButton()

    let captionLabel = makeCaptionLabel()

    weak var delegate: SettingsTextFieldDelegate?
    public private (set) var caption: String?
    private var rules: [(regex: NSRegularExpression, error: String?)] = []

    public convenience init(type: UIKeyboardType) {
        self.init(frame: .zero)
        configureUI()
        textField.keyboardType = type
        isSecureButton.addTarget(self, action: #selector(secureText), for: .touchUpInside)
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        textField.delegate = self
        translatesAutoresizingMaskIntoConstraints = false
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func focusOnTextField() {
        textField.becomeFirstResponder()
    }

    public var text: String? {
        textField.text
    }

    public func setCaption(_ caption: String?) {
        self.caption = caption
        captionLabel.text = caption
    }

    public func addRule(rule: NSRegularExpression, error: String?) {
        rules.append((rule, error))
    }

    public func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    public func setTemporaryError(_ error: String) {
        captionLabel.text = error
        didFindError()
    }

    private func configureUI() {
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: self.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(secondaryStack)

        secondaryStack.addArrangedSubview(inputContainerView)
        secondaryStack.addArrangedSubview(captionLabel)

        titleLabel.setContentCompressionResistancePriority(1000, for: .vertical)
        captionLabel.setContentCompressionResistancePriority(1000, for: .vertical)

        inputContainerView.addSubview(textFieldStack)
        textFieldStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldStack.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            textFieldStack.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),
            textFieldStack.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 8),
            textFieldStack.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -8)
        ])

        textFieldStack.addArrangedSubview(textField)
        textFieldStack.addArrangedSubview(isSecureButton)
    }

    @objc func secureText() {
        textField.isSecureTextEntry.toggle()
        let newImage: UIImage = textField.isSecureTextEntry ? IconProvider.eye : IconProvider.eyeSlash
        isSecureButton.setBackgroundImage(newImage, for: .normal)
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        guard let textFieldText = textField.text else { return }
        delegate?.textField(didChangeText: textFieldText)
        removeTemporaryError()
        for (regex, error) in rules {
            if regex.isRegexCompliant(for: textFieldText) {
                didLeaveError()
                captionLabel.text = caption
            } else {
                didFindError()
                return captionLabel.text = error
            }
        }
    }

    private func didFindError() {
        titleLabel.textColor = ColorProvider.NotificationError
        captionLabel.textColor = ColorProvider.NotificationError
        inputContainerView.layer.borderColor = ColorProvider.NotificationError.cgColor
    }

    private func didLeaveError() {
        titleLabel.style = LabelStyles.captionSemiBold
        inputContainerView.layer.borderColor = ColorProvider.BrandLighten40.cgColor
        captionLabel.style = LabelStyles.caption
    }

    private func removeTemporaryError() {
        captionLabel.text = caption
        didLeaveError()
    }

    private static func makeInputContainerdView() -> UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorProvider.BrandLighten40.cgColor
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        view.setSizeContraint(height: 48, width: nil)
        return view
    }

    private static func makeTitleLabel() -> UILabel {
        let label = UILabel(LabelStyles.captionSemiBold)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }

    private static func makeCaptionLabel() -> UILabel {
        let label = UILabel(LabelStyles.caption)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }

    private static func makeTextField() -> UITextField {
        let textField = PasswordTextField()
        textField.isSecureTextEntry = true
        textField.font = .systemFont(ofSize: 17)
        textField.setSizeContraint(height: 22, width: nil)
        return textField
    }

    private static func makeClearTextButton() -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = ColorProvider.BrandLighten20
        button.setBackgroundImage(IconProvider.eye, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 20),
            button.widthAnchor.constraint(equalToConstant: 20)
        ])
        return button
    }
}

private final class PasswordTextField: UITextField {
    override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }

    /// Override `becomeFirstResponder` so that `PasswordTextField` is able to delete only last character when focusing again instead Apple's default behavior of clearing all the text
    override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        guard isSecureTextEntry,
              let currentText = text else {
            return didBecome
        }
        text?.removeAll()
        insertText(currentText)
        insertAndRemoveExtraCharaterToAvoidShowingPasswordLastCharachterOnFocus()
        return didBecome
    }

    private func insertAndRemoveExtraCharaterToAvoidShowingPasswordLastCharachterOnFocus() {
        insertText("+")
        deleteBackward()
    }
}

// Make public on PMUIFrameworks
extension UIStackView {
    convenience init(_ axis: NSLayoutConstraint.Axis,
                     alignment: UIStackView.Alignment,
                     distribution: UIStackView.Distribution,
                     spacing: CGFloat = 0) {
        self.init(frame: .zero)
        self.axis = axis
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
        translatesAutoresizingMaskIntoConstraints = false
    }
}
