//
// TextFieldWithToolbar.swift
// Proton Pass - Created on 05/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Combine
import SwiftUI

// https://stackoverflow.com/a/59115092/2034535
public struct TextFieldWithToolbar: UIViewRepresentable {
    private let toolbar: UIToolbar
    private let placeholder: String
    let onEditingChange: (Bool) -> Void
    @Binding private var isSecureTextEntry: Bool
    @Binding var text: String

    public init(text: Binding<String>,
                isSecureTextEntry: Binding<Bool>,
                placeholder: String,
                toolbar: UIToolbar,
                onEditingChange: @escaping (Bool) -> Void) {
        self._text = text
        self._isSecureTextEntry = isSecureTextEntry
        self.placeholder = placeholder
        self.toolbar = toolbar
        self.onEditingChange = onEditingChange
    }

    let textField = UITextField(frame: .zero)

    public func makeUIView(context: Context) -> UITextField {
        textField.placeholder = placeholder
        textField.inputAccessoryView = toolbar
        return textField
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isSecureTextEntry
    }

    public func makeCoordinator() -> Coordinator { .init(self) }

    public final class Coordinator: NSObject {
        private var cancellables = Set<AnyCancellable>()

        init(_ owner: TextFieldWithToolbar) {
            NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification,
                           object: owner.textField)
                .sink { _ in
                    owner.$text.wrappedValue = owner.textField.text ?? ""
                }
                .store(in: &cancellables)

            NotificationCenter.default
                .publisher(for: UITextField.textDidBeginEditingNotification,
                           object: owner.textField)
                .sink { _ in
                    owner.onEditingChange(true)
                }
                .store(in: &cancellables)

            NotificationCenter.default
                .publisher(for: UITextField.textDidEndEditingNotification,
                           object: owner.textField)
                .sink { _ in
                    owner.onEditingChange(false)
                }
                .store(in: &cancellables)
        }
    }
}
