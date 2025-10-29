//
// BackspaceAwareTextField.swift
// Proton Pass - Created on 02/01/2024.
// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.
//

import SwiftUI

private protocol DeleteBackwardDelegate: UITextFieldDelegate {
    func didDeleteBackward()
}

private final class BackspaceAwareUITextField: UITextField {
    override func deleteBackward() {
        super.deleteBackward()
        (delegate as? DeleteBackwardDelegate)?.didDeleteBackward()
    }
}

public struct BackspaceAwareTextField: UIViewRepresentable {
    @Binding private var text: String
    @Binding private var isFocused: Bool
    private let config: BackspaceAwareTextField.Configuration
    let onBackspace: () -> Void
    let onReturn: () -> Void

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                config: BackspaceAwareTextField.Configuration,
                onBackspace: @escaping () -> Void,
                onReturn: @escaping () -> Void) {
        _text = text
        _isFocused = isFocused
        self.config = config
        self.onBackspace = onBackspace
        self.onReturn = onReturn
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = BackspaceAwareUITextField()
        textField.font = config.font
        textField.placeholder = config.placeholder
        textField.autocapitalizationType = config.autoCapitalization
        textField.autocorrectionType = config.autoCorrection
        textField.keyboardType = config.keyboardType
        textField.returnKeyType = config.returnKeyType
        textField.textColor = config.textColor
        textField.tintColor = config.tintColor
        textField.addAction(UIAction(handler: { _ in
            text = textField.text ?? ""
        }), for: .editingChanged)
        textField.delegate = context.coordinator
        return textField
    }

    public func updateUIView(_ textField: UITextField, context: Context) {
        if isFocused {
            textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        textField.text = text
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

public extension BackspaceAwareTextField {
    final class Coordinator: NSObject, DeleteBackwardDelegate {
        let parent: BackspaceAwareTextField

        init(_ parent: BackspaceAwareTextField) {
            self.parent = parent
        }

        func didDeleteBackward() {
            parent.onBackspace()
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn()
            return true
        }
    }
}

public extension BackspaceAwareTextField {
    struct Configuration {
        let font: UIFont
        let placeholder: String
        let autoCapitalization: UITextAutocapitalizationType
        let autoCorrection: UITextAutocorrectionType
        let keyboardType: UIKeyboardType
        let returnKeyType: UIReturnKeyType
        let textColor: UIColor
        let tintColor: UIColor

        public init(font: UIFont,
                    placeholder: String,
                    autoCapitalization: UITextAutocapitalizationType,
                    autoCorrection: UITextAutocorrectionType,
                    keyboardType: UIKeyboardType,
                    returnKeyType: UIReturnKeyType,
                    textColor: UIColor,
                    tintColor: UIColor) {
            self.font = font
            self.placeholder = placeholder
            self.autoCapitalization = autoCapitalization
            self.autoCorrection = autoCorrection
            self.keyboardType = keyboardType
            self.returnKeyType = returnKeyType
            self.textColor = textColor
            self.tintColor = tintColor
        }
    }
}
