//
// UserInputContentView.swift
// Proton Pass - Created on 08/08/2022.
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
import Introspect
import ProtonCore_UIFoundations
import SwiftUI

public struct UserInputContentSingleLineView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                placeholder: String) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
    }

    public var body: some View {
        TextField(placeholder, text: $text) { editingChanged in
            isFocused = editingChanged
        }
    }
}

// swiftlint:disable:next type_name
public struct UserInputContentSingleLineWithTrailingView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let trailingIcon: UIImage
    let trailingAction: () -> Void

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                placeholder: String,
                trailingIcon: UIImage,
                trailingAction: @escaping () -> Void) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
    }

    public var body: some View {
        HStack {
            TextField(placeholder, text: $text) { editingChanged in
                isFocused = editingChanged
            }

            Button(action: trailingAction) {
                Image(uiImage: trailingIcon)
            }
            .foregroundColor(.primary)
        }
    }
}

public struct UserInputContentMultilineView: View {
    @Binding var text: String
    @Binding var isFocused: Bool

    public init(text: Binding<String>,
                isFocused: Binding<Bool>) {
        self._text = text
        self._isFocused = isFocused
    }

    public var body: some View {
        SwiftUITextView(text: $text) { editingChange in
            isFocused = editingChange
        }
        .frame(height: 100)
    }
}

private final class UserInputContentPasswordViewModel {
    @Published var isFocused = false
    private var cancellables = Set<AnyCancellable>()

    func observe(textField: UITextField) {
        NotificationCenter.default
            .publisher(for: UITextField.textDidBeginEditingNotification,
                       object: textField)
            .sink { [unowned self] _ in
                self.isFocused = true
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UITextField.textDidEndEditingNotification,
                       object: textField)
            .sink {[unowned self] _ in
                self.isFocused = false
            }
            .store(in: &cancellables)
    }
}

public struct UserInputContentPasswordView: View {
    private let viewModel = UserInputContentPasswordViewModel()
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var isSecure: Bool
    let toolbar: UIToolbar

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                isSecure: Binding<Bool>,
                toolbar: UIToolbar) {
        self._text = text
        self._isFocused = isFocused
        self._isSecure = isSecure
        self.toolbar = toolbar
    }

    public var body: some View {
        HStack {
            let placeholder = "Add password"
            if isSecure {
                SecureField(placeholder, text: $text)
                    .introspectTextField { textField in
                        textField.inputAccessoryView = toolbar
                        viewModel.observe(textField: textField)
                    }
            } else {
                TextField(placeholder, text: $text)
                    .introspectTextField { textField in
                        textField.inputAccessoryView = toolbar
                        viewModel.observe(textField: textField)
                    }
            }

            Button(action: {
                isSecure.toggle()
            }, label: {
                Image(uiImage: isSecure ? IconProvider.eye : IconProvider.eyeSlash)
            })
            .foregroundColor(.primary)
        }
        .onReceive(Just(viewModel.isFocused)) { isFocused in
            self.isFocused = isFocused
        }
    }
}
