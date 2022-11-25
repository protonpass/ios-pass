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
import ProtonCore_UIFoundations
import SwiftUI

public struct UserInputContentSingleLineView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let keyboardType: UIKeyboardType
    let textAutocapitalizationType: UITextAutocapitalizationType

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                placeholder: String,
                keyboardType: UIKeyboardType = .default,
                textAutocapitalizationType: UITextAutocapitalizationType = .sentences) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.textAutocapitalizationType = textAutocapitalizationType
    }

    public var body: some View {
        TextField(placeholder, text: $text) { editingChanged in
            isFocused = editingChanged
        }
        .keyboardType(keyboardType)
        .autocapitalization(textAutocapitalizationType)
    }
}

// swiftlint:disable:next type_name
public struct UserInputContentSingleLineWithTrailingView<TrailingView: View>: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let keyboardType: UIKeyboardType
    let textAutocapitalizationType: UITextAutocapitalizationType
    let trailingView: () -> TrailingView
    let trailingAction: () -> Void

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                placeholder: String,
                trailingView: @escaping () -> TrailingView,
                trailingAction: @escaping () -> Void,
                keyboardType: UIKeyboardType = .default,
                textAutocapitalizationType: UITextAutocapitalizationType = .sentences) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.textAutocapitalizationType = textAutocapitalizationType
        self.trailingView = trailingView
        self.trailingAction = trailingAction
    }

    public var body: some View {
        HStack {
            TextField(placeholder, text: $text) { editingChanged in
                isFocused = editingChanged
            }
            .keyboardType(keyboardType)
            .autocapitalization(textAutocapitalizationType)

            Button(action: trailingAction) {
                trailingView()
                    .foregroundColor(.iconHint)
            }
            .foregroundColor(.primary)
        }
    }
}

// swiftlint:disable:next type_name
public struct UserInputContentSingleLineWithClearButton: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let keyboardType: UIKeyboardType
    let textAutocapitalizationType: UITextAutocapitalizationType
    let onClear: () -> Void

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                placeholder: String,
                onClear: @escaping () -> Void,
                keyboardType: UIKeyboardType = .default,
                textAutocapitalizationType: UITextAutocapitalizationType = .sentences) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.textAutocapitalizationType = textAutocapitalizationType
        self.onClear = onClear
    }

    public var body: some View {
        UserInputContentSingleLineWithTrailingView(
            text: $text,
            isFocused: $isFocused,
            placeholder: placeholder,
            trailingView: {
                Image(uiImage: IconProvider.crossCircleFilled)
                    .opacityReduced(!isFocused, reducedOpacity: 0)
                    .animation(.linear(duration: 0.1), value: isFocused)
            },
            trailingAction: onClear,
            keyboardType: keyboardType,
            textAutocapitalizationType: textAutocapitalizationType)
    }
}

public struct UserInputContentMultilineView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let height: CGFloat

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                height: CGFloat = 256) {
        self._text = text
        self._isFocused = isFocused
        self.height = height
    }

    public var body: some View {
        SwiftUITextView(text: $text) { editingChange in
            isFocused = editingChange
        }
        .frame(height: height)
    }
}

public struct UserInputStaticContentView<TrailingView: View>: View {
    let text: String
    let trailingView: TrailingView

    public init(text: String,
                @ViewBuilder trailingView: () -> TrailingView = { EmptyView() }) {
        self.text = text
        self.trailingView = trailingView()
    }

    public var body: some View {
        HStack {
            Text(text)
            Spacer()
            trailingView
        }
    }
}

public struct UserInputContentPasswordView: View {
    @FocusState private var focusState: Bool
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var isSecure: Bool

    public init(text: Binding<String>,
                isFocused: Binding<Bool>,
                isSecure: Binding<Bool>) {
        self._text = text
        self._isFocused = isFocused
        self._isSecure = isSecure
    }

    public var body: some View {
        HStack {
            let placeholder = "Add password"
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($focusState)
            } else {
                TextField(placeholder, text: $text)
                    .focused($focusState)
            }

            Button(action: {
                isSecure.toggle()
            }, label: {
                Image(uiImage: isSecure ? IconProvider.eye : IconProvider.eyeSlash)
                    .foregroundColor(.iconHint)
            })
            .foregroundColor(.primary)
        }
        .onReceive(Just(focusState)) { isFocused in
            self.isFocused = isFocused
        }
    }
}

public struct UserInputContentURLsView: View {
    @Binding var urls: [String]
    @Binding var isFocused: Bool
    @Binding var invalidUrls: [String]

    public init(urls: Binding<[String]>,
                isFocused: Binding<Bool>,
                invalidUrls: Binding<[String]>) {
        self._urls = urls
        self._isFocused = isFocused
        self._invalidUrls = invalidUrls
    }

    public var body: some View {
        VStack {
            ForEach(urls.indices, id: \.self) { index in
                let urlBinding = Binding<String>(get: {
                    urls[index]
                }, set: { newValue in
                    withAnimation {
                        urls[index] = newValue.lowercased()
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                })
                HStack {
                    TextField("https://", text: urlBinding) { editingChanged in
                        isFocused = editingChanged
                        if !isFocused, index != 0, urls[index].isEmpty {
                            urls.remove(at: index)
                        }
                    }
                    .onChange(of: urls) { _ in
                        invalidUrls.removeAll()
                    }
                    .keyboardType(.URL)
                    .disableAutocorrection(true)
                    .foregroundColor(isValidUrl(index: index) ? .primary : .red)

                    if !urls[index].isEmpty || index != 0 {
                        Button(action: {
                            withAnimation {
                                if urls.count == 1 {
                                    urls[index] = ""
                                } else {
                                    urls.remove(at: index)
                                }
                            }
                        }, label: {
                            Image(uiImage: IconProvider.cross)
                        })
                        .foregroundColor(.primary)
                    }
                }

                if urls.count > 1 || urls.first?.isEmpty == false {
                    Divider()
                }
            }

            addUrlButton
        }
        .animation(.default, value: urls.count)
    }

    private func isValidUrl(index: Int) -> Bool {
        guard urls.indices.contains(index) else { return true }
        let url = urls[index]
        return !invalidUrls.contains(url)
    }

    @ViewBuilder
    private var addUrlButton: some View {
        if urls.first?.isEmpty == false {
            Button(action: {
                if urls.last?.isEmpty == false {
                    // Only add new URL when last URL has value to avoid adding blank URLs
                    urls.append("")
                }
            }, label: {
                Label(title: {
                    Text("Add another website")
                }, icon: {
                    Image(uiImage: IconProvider.plus)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
    }
}
