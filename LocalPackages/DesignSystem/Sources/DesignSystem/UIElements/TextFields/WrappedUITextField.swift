//
// WrappedUITextField.swift
// Proton Pass - Created on 21/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import SwiftUI

public struct WrappedUITextFieldConfiguration {
    let shouldActivateCursorMovement: Bool
    let keyboardType: UIKeyboardType
    let autoCorrection: UITextAutocorrectionType
    let returnKeyType: UIReturnKeyType

    public init(shouldActivateCursorMovement: Bool,
                keyboardType: UIKeyboardType,
                autoCorrection: UITextAutocorrectionType,
                returnKeyType: UIReturnKeyType) {
        self.shouldActivateCursorMovement = shouldActivateCursorMovement
        self.keyboardType = keyboardType
        self.autoCorrection = autoCorrection
        self.returnKeyType = returnKeyType
    }

    public static var defaultCreditCardField: WrappedUITextFieldConfiguration {
        WrappedUITextFieldConfiguration(shouldActivateCursorMovement: true,
                                        keyboardType: .numberPad,
                                        autoCorrection: .no,
                                        returnKeyType: .next)
    }
}

public struct WrappedUITextField: UIViewRepresentable {
    @Binding var text: String
    @State private var position: Int = 0
    @State private var deleting = false
    private var placeHolder: String
    private let configuration: WrappedUITextFieldConfiguration
    private var isEditing: (Bool) -> Void

    public init(text: Binding<String>,
                placeHolder: String,
                configuration: WrappedUITextFieldConfiguration = .defaultCreditCardField,
                isEditing: @escaping (Bool) -> Void) {
        _text = text
        self.placeHolder = placeHolder
        self.configuration = configuration
        self.isEditing = isEditing
    }

    public func makeCoordinator() -> WrappedUITextFieldCoordinator {
        WrappedUITextFieldCoordinator($text,
                                      position: $position,
                                      isDeleting: $deleting,
                                      isEditing: isEditing)
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.text = text
        textField.placeholder = placeHolder
        textField.keyboardType = configuration.keyboardType
        textField.autocorrectionType = configuration.autoCorrection
        textField.returnKeyType = configuration.returnKeyType
        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        guard text != context.coordinator.currentText else {
            return
        }
        DispatchQueue.main.async {
            uiView.text = text
            if configuration.shouldActivateCursorMovement {
                moveCursorToNextPosition(from: position, in: text, container: uiView)
            }
        }
    }

    func moveCursorToNextPosition(from oldPosition: Int, in text: String, container uiView: UITextField) {
        var refPosition = deleting ? oldPosition - 1 : oldPosition + 1
        if !text.replacingOccurrences(of: " ", with: "").count.isMultiple(of: 2), !deleting {
            refPosition += 1
        }
        if refPosition <= uiView.cursorCurrentPosition {
            if let newPosition = uiView.position(from: uiView.beginningOfDocument, offset: refPosition) {
                uiView.selectedTextRange = uiView.textRange(from: newPosition, to: newPosition)
            }
        }
    }

    public class WrappedUITextFieldCoordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var currentText: String
        var position: Binding<Int>
        var isDeleting: Binding<Bool>
        var isEditing: (Bool) -> Void

        public init(_ text: Binding<String>,
                    position: Binding<Int>,
                    isDeleting: Binding<Bool>,
                    isEditing: @escaping (Bool) -> Void) {
            self.text = text
            self.position = position
            self.isDeleting = isDeleting
            self.isEditing = isEditing
            currentText = text.wrappedValue
        }

        public func textField(_ textField: UITextField,
                              shouldChangeCharactersIn range: NSRange,
                              replacementString string: String) -> Bool {
            guard let oldText = textField.text, let textRange = Range(range, in: oldText) else {
                return false
            }

            position.wrappedValue = textField.cursorCurrentPosition
            currentText = oldText.replacingCharacters(in: textRange, with: string)
            text.wrappedValue = currentText
            isDeleting.wrappedValue = oldText.count > text.wrappedValue.count
            return true
        }

        public func textFieldDidBeginEditing(_ textField: UITextField) {
            isEditing(true)
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            isEditing(false)
            return true
        }
    }
}
