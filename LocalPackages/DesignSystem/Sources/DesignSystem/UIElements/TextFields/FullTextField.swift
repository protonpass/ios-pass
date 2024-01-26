//
// FullTextField.swift
// Proton Pass - Created on 25/01/2024.
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

import Foundation
import SwiftUI
import UIKit

/// A wrapper **text field** ⌨️ around the `UITextField`, harnessing its fully functionality 💪,
/// that can be used using entirely SwiftUI like an ordinary `TextField`. 😲😃
public struct FullTextField: UIViewRepresentable {
    private var placeholder: String
    @Binding private var text: String

    @State private var internalIsEditing = false
    @Binding private var externalIsEditing: Bool
    private var isEditing: Binding<Bool> {
        hasExternalIsEditing ? $externalIsEditing : $internalIsEditing
    }

    private var hasExternalIsEditing = false
    var designEditing: Bool { externalIsEditing }

    var didBeginEditing: () -> Void = {}
    var didChange: () -> Void = {}
    var didEndEditing: () -> Void = {}
    var shouldReturn: () -> Void = {}
    var shouldClear: () -> Void = {}

    var font: UIFont?
    var foregroundColor: UIColor?
    var accentColor: UIColor?
    var placeholderColor: UIColor?
    var textAlignment: NSTextAlignment?
    var contentType: UITextContentType?

    var autocorrection: UITextAutocorrectionType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var characterLimit: Int?

    var isSecure = false
    var isUserInteractionEnabled = true
    var clearsOnBeginEditing = false
    var clearsOnInsertion = false
    var clearButtonMode: UITextField.ViewMode = .never

    var passwordRules: UITextInputPasswordRules?
    var smartDashesType: UITextSmartDashesType = .default
    var smartInsertDeleteType: UITextSmartInsertDeleteType = .default
    var smartQuotesType: UITextSmartQuotesType = .default
    var spellCheckingType: UITextSpellCheckingType = .default

    @Environment(\.layoutDirection) var layoutDirection: LayoutDirection
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    /// Initializes a new **text field** 👷‍♂️⌨️ with enhanced functionality. 🏋️‍♀️
    /// - Parameters:
    ///   - placeholder: The text to display in the text field when nothing has been inputted
    ///   - text: A binding to the text `String` to be edited by the text field 📱
    ///   - isEditing: A binding to a `Bool` indicating whether the text field is being edited 💻💬
    public init(_ placeholder: String,
                text: Binding<String>,
                isEditing: Binding<Bool>? = nil) {
        self.placeholder = placeholder
        _text = text
        if let isEditing {
            _externalIsEditing = isEditing
            hasExternalIsEditing = true
        } else {
            _externalIsEditing = Binding<Bool>(get: { false }, set: { _ in })
        }
    }

    /// All these properties need to be set in exactly the same way to make the UIView and to update the UIView
    private func setProperties(_ textField: UITextField) {
        // Accessing the Text Attributes
        textField.text = text
        if let placeholderColor {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                 attributes: [.foregroundColor: placeholderColor])
        } else {
            textField.placeholder = placeholder
        }
        textField.font = font
        textField.textColor = foregroundColor
        if let textAlignment {
            textField.textAlignment = textAlignment
        }

        textField.clearsOnBeginEditing = clearsOnBeginEditing
        textField.clearsOnInsertion = clearsOnInsertion

        // Other settings
        if let contentType {
            textField.textContentType = contentType
        }
        if let accentColor {
            textField.tintColor = accentColor
        }
        textField.clearButtonMode = clearButtonMode
        textField.autocorrectionType = autocorrection
        textField.autocapitalizationType = autocapitalization
        textField.keyboardType = keyboardType
        textField.returnKeyType = returnKeyType

        textField.isUserInteractionEnabled = isUserInteractionEnabled

        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textField.passwordRules = passwordRules
        textField.smartDashesType = smartDashesType
        textField.smartInsertDeleteType = smartInsertDeleteType
        textField.smartQuotesType = smartQuotesType
        textField.spellCheckingType = spellCheckingType
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()

        // Validating and Handling Edits
        textField.delegate = context.coordinator

        setProperties(textField)

        textField.isSecureTextEntry = isSecure

        // Managing the Editing Behavior
        DispatchQueue.main.async {
            if isEditing.wrappedValue {
                textField.becomeFirstResponder()
            }
        }

        textField.addTarget(context.coordinator,
                            action: #selector(Coordinator.textFieldDidChange(_:)),
                            for: .editingChanged)

        return textField
    }

    public func updateUIView(_ textField: UITextField, context: Context) {
        setProperties(textField)

        /// # Handling the toggling of isSecure correctly
        ///
        /// To ensure that the cursor position is maintained when toggling secureTextEntry
        /// we can read the cursor position before updating the property and set it back afterwards.
        ///
        /// UITextField also deletes all the existing text whenever secureTextEntry goes from false to true.
        /// We work around that by procedurely removing and re-adding the text here.

        if isSecure != textField.isSecureTextEntry {
            var start: UITextPosition?
            var end: UITextPosition?

            if let selectedRange = textField.selectedTextRange {
                start = selectedRange.start
                end = selectedRange.end
            }

            textField.isSecureTextEntry = isSecure
            if isSecure, isEditing.wrappedValue {
                if let currentText = textField.text {
                    textField.text?.removeAll()
                    textField.insertText(currentText)
                }
            }
            if isEditing.wrappedValue {
                if let start, let end {
                    textField.selectedTextRange = textField.textRange(from: start, to: end)
                }
            }
        }

        DispatchQueue.main.async {
            if isEditing.wrappedValue {
                textField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    isEditing: isEditing,
                    characterLimit: characterLimit,
                    didBeginEditing: didBeginEditing,
                    didChange: didChange,
                    didEndEditing: didEndEditing,
                    shouldReturn: shouldReturn,
                    shouldClear: shouldClear)
    }

    public final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isEditing: Bool
        var characterLimit: Int?

        var didBeginEditing: () -> Void
        var didChange: () -> Void
        var didEndEditing: () -> Void
        var shouldReturn: () -> Void
        var shouldClear: () -> Void

        init(text: Binding<String>,
             isEditing: Binding<Bool>,
             characterLimit: Int?,
             didBeginEditing: @escaping () -> Void,
             didChange: @escaping () -> Void,
             didEndEditing: @escaping () -> Void,
             shouldReturn: @escaping () -> Void,
             shouldClear: @escaping () -> Void) {
            _text = text
            _isEditing = isEditing
            self.characterLimit = characterLimit
            self.didBeginEditing = didBeginEditing
            self.didChange = didChange
            self.didEndEditing = didEndEditing
            self.shouldReturn = shouldReturn
            self.shouldClear = shouldClear
        }

        public func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async { [self] in
                if !isEditing {
                    isEditing = true
                }
                if textField.clearsOnBeginEditing {
                    text = ""
                }
                didBeginEditing()
            }
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
            didChange()
        }

        public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            DispatchQueue.main.async { [self] in
                if isEditing {
                    isEditing = false
                }
                didEndEditing()
            }
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            isEditing = false
            shouldReturn()
            return false
        }

        public func textFieldShouldClear(_ textField: UITextField) -> Bool {
            shouldClear()
            text = ""
            return false
        }

        public func textField(_ textField: UITextField,
                              shouldChangeCharactersIn range: NSRange,
                              replacementString string: String) -> Bool {
            // if there is a character limit set and new text will be greater than limt, then don't allow the newly
            // proposed edit
            if let limit = characterLimit, let text = textField.text {
                if text.count + string.count > limit {
                    return false
                }
            }

            return true
        }
    }
}

public extension FullTextField {
    /// Sets the maximum amount of characters allowed in this text field.
    /// - Parameter limit: the maximum amount of characters allowed
    /// - Returns: An updated text field limited to limit
    func characterLimit(_ limit: Int?) -> FullTextField {
        var view = self
        view.characterLimit = limit
        return view
    }

    /// Modifies the text field’s **font** from a `UIFont` object. 🔠🔡
    /// - Parameter font: The desired font 🅰️🆗
    /// - Returns: An updated text field using the desired font 💬
    /// - Warning: ⚠️ Accepts a `UIFont` object rather than SwiftUI `Font` ⚠️
    /// - SeeAlso: [`UIFont`](https://developer.apple.com/documentation/uikit/uifont)
    func fontFromUIFont(_ font: UIFont?) -> FullTextField {
        var view = self
        view.font = font
        return view
    }

    /// Modifies the **text color** 🎨 of the text field.
    /// - Parameter color: The desired text color 🌈
    /// - Returns: An updated text field using the desired text color 🚦
    func foregroundColor(_ color: Color?) -> FullTextField {
        var view = self
        if let color {
            view.foregroundColor = UIColor(color)
        }
        return view
    }

    /// Modifies the **cursor color** 🌈 of the text field 🖱 💬
    /// - Parameter accentColor: The cursor color 🎨
    /// - Returns: A phone number text field with updated cursor color 🚥🖍
    func accentColor(_ accentColor: Color?) -> FullTextField {
        var view = self
        if let accentColor {
            view.accentColor = UIColor(accentColor)
        }
        return view
    }

    /// Modifies the **placeholder color** 🌈 of the text field 🖱 💬
    /// - Parameter placeholderColor: The color for placeholder 🎨
    /// - Returns: A text field with updated placeholder color 🚥🖍
    func placeholderColor(_ placeholderColor: Color?) -> FullTextField {
        var view = self
        if let placeholderColor {
            view.placeholderColor = UIColor(placeholderColor)
        }
        return view
    }

    /// Modifies the **text alignment** of a text field. ⬅️ ↔️ ➡️
    /// - Parameter alignment: The desired text alignment 👈👉
    /// - Returns: An updated text field using the desired text alignment ↩️↪️
    func multilineTextAlignment(_ alignment: TextAlignment) -> FullTextField {
        var view = self
        switch alignment {
        case .leading:
            view.textAlignment = layoutDirection ~= .leftToRight ? .left : .right
        case .trailing:
            view.textAlignment = layoutDirection ~= .leftToRight ? .right : .left
        case .center:
            view.textAlignment = .center
        }
        return view
    }

    /// Modifies the **content type** of a text field. 📧 ☎️ 📬
    /// - Parameter textContentType: The type of text being inputted into the text field ⌨️
    /// - Returns: An updated text field using the desired text content type 💻📨
    func textContentType(_ textContentType: UITextContentType?) -> FullTextField {
        var view = self
        view.contentType = textContentType
        return view
    }

    /// Modifies the text field’s **autocorrection** settings. 💬
    /// - Parameter disable: Whether autocorrection should be disabled ❌
    /// - Returns: An updated text field using the desired autocorrection settings 📝
    func disableAutocorrection(_ disable: Bool = false) -> FullTextField {
        var view = self
        view.autocorrection = disable ? .no : .yes
        return view
    }

    /// Modifies the text field’s **autocapitalization** style. 🔡🔠
    /// - Parameter style: What types of characters should be autocapitalized
    /// - Returns: An updated text field using the desired autocapitalization style
    func autocapitalization(_ style: UITextAutocapitalizationType) -> FullTextField {
        var view = self
        view.autocapitalization = style
        return view
    }

    /// Modifies the text field’s **keyboard type**. 📩🕸🧒
    /// - Parameter type: The type of keyboard that the user should get to type in the text field
    /// - Returns: An updated text field using the desired keyboard type
    func keyboardType(_ type: UIKeyboardType) -> FullTextField {
        var view = self
        view.keyboardType = type
        return view
    }

    /// Modifies the text field’s **return key** type. 🆗✅
    /// - Parameter type: The type of return key the user should get on the keyboard when using this text field
    /// - Returns: An updated text field using the desired return key type
    func returnKeyType(_ type: UIReturnKeyType) -> FullTextField {
        var view = self
        view.returnKeyType = type
        return view
    }

    /// Modifies the text field’s **secure entry** settings. 🔒🚨
    /// - Parameter isSecure: Whether the text field should hide the entered characters as dots
    /// - Returns: An updated text field using the desired secure entry settings
    func isSecure(_ isSecure: Bool) -> FullTextField {
        var view = self
        view.isSecure = isSecure
        return view
    }

    /// Modifies the **clear-on-begin-editing** setting of a  text field. ❌▶️
    /// - Parameter shouldClear: Whether the text field should clear on editing beginning 📭🏁
    /// - Returns:  A text field with updated clear-on-begin-editing settings 🔁
    func clearsOnBeginEditing(_ shouldClear: Bool) -> FullTextField {
        var view = self
        view.clearsOnBeginEditing = shouldClear
        return view
    }

    /// Modifies the **clear-on-insertion** setting of a text field. 👆
    /// - Parameter shouldClear: Whether the text field should clear on insertion
    /// - Returns: A text field with updated clear-on-insertion settings
    func clearsOnInsertion(_ shouldClear: Bool) -> FullTextField {
        var view = self
        view.clearsOnInsertion = shouldClear
        return view
    }

    /// Modifies whether and when the text field **clear button** appears on the view. ⭕️ ❌
    /// - Parameter showsButton: Whether the clear button should be visible
    /// - Returns: A text field with updated clear button settings
    func showsClearButton(_ showsButton: Bool) -> FullTextField {
        var view = self
        view.clearButtonMode = showsButton ? .always : .never
        return view
    }

    /// Modifies whether the text field is **disabled**. ✋
    /// - Parameter disabled: Whether the text field is disabled 🛑
    /// - Returns: A text field with updated disabled settings ⬜️⚙️
    func disabled(_ disabled: Bool) -> FullTextField {
        var view = self
        view.isUserInteractionEnabled = !disabled
        return view
    }

    /// Modifies the text field's **password rules** 🔒. Sets secure entry to `true`.
    /// - Parameter rules: The text field's password rules.
    /// - Returns: A text field with updated password rules
    func passwordRules(_ rules: UITextInputPasswordRules) -> FullTextField {
        var view = self
        view.isSecure = true
        view.passwordRules = rules
        return view
    }

    /// Modifies whether the text field includes **smart dashes**.
    /// - Parameter smartDashes: Whether the text field includes smart dashes. Does nothing if `nil`.
    /// - Returns: A text field with the updated smart dashes settings.
    func smartDashes(_ smartDashes: Bool = true) -> FullTextField {
        var view = self
        view.smartDashesType = smartDashes ? .yes : .no
        return view
    }

    /// Modifies whether the text field uses **smart insert-delete**.
    /// - Parameter smartInsertDelete: Whether the text field uses smart insert-delete. Does nothing if `nil`.
    /// - Returns: A text field with the updated smart insert-delete settings.
    func smartInsertDelete(_ smartInsertDelete: Bool = false) -> FullTextField {
        var view = self
        view.smartInsertDeleteType = smartInsertDelete ? .yes : .no
        return view
    }

    /// Modifies whether the text field uses **smart quotes**.
    /// - Parameter smartQuotes: Whether the text field uses smart quotes. Does nothing if `nil`.
    /// - Returns: A text field with the updated smart quotes settings
    func smartQuotes(_ smartQuotes: Bool = true) -> FullTextField {
        var view = self
        view.smartQuotesType = smartQuotes ? .yes : .no
        return view
    }

    /// Modifies whether the text field should check the user's **spelling** 🔡
    /// - Parameter spellChecking: Whether the text field should check the user's spelling. Does nothing if `nil`.
    /// - Returns: A text field with updated spell checking settings
    func spellChecking(_ spellChecking: Bool = true) -> FullTextField {
        var view = self
        view.spellCheckingType = spellChecking ? .yes : .no
        return view
    }

    /// Modifies the function called when text editing **begins**. ▶️
    /// - Parameter action: The function called when text editing begins 🏁. Does nothing if `nil`.
    /// - Returns: An updated text field using the desired function called when text editing begins ➡️
    func onEditingBegan(perform action: (() -> Void)? = nil) -> FullTextField {
        var view = self
        if let action {
            view.didBeginEditing = action
        }
        return view
    }

    /// Modifies the function called when the user makes any **changes** to the text in the text field. 💬
    /// - Parameter action: The function called when the user makes any changes to the text in the text field ⚙️.
    /// Does nothing if `nil`.
    /// - Returns: An updated text field using the desired function called when the user makes any changes to the
    /// text in the text field 🔄
    func onEdit(perform action: (() -> Void)? = nil) -> FullTextField {
        var view = self
        if let action {
            view.didChange = action
        }
        return view
    }

    /// Modifies the function called when text editing **ends**. 🔚
    /// - Parameter action: The function called when text editing ends 🛑. Does nothing if `nil`.
    /// - Returns: An updated text field using the desired function called when text editing ends ✋
    func onEditingEnded(perform action: (() -> Void)? = nil) -> FullTextField {
        var view = self
        if let action {
            view.didEndEditing = action
        }
        return view
    }

    /// Modifies the function called when the user presses the return key. ⬇️ ➡️
    /// - Parameter action: The function called when the user presses the return key. Does nothing if `nil`.
    /// - Returns: An updated text field using the desired funtion called when the user presses the return key
    func onReturn(perform action: (() -> Void)? = nil) -> FullTextField {
        var view = self
        if let action {
            view.shouldReturn = action
        }
        return view
    }

    /// Modifies the function called when the user clears the text field. ❌
    /// - Parameter action: The function called when the user clears the text field. Does nothing if `nil`.
    /// - Returns: An updated text field using the desired function called when the user clears the text field
    func onClear(perform action: (() -> Void)? = nil) -> FullTextField {
        var view = self
        if let action {
            view.shouldClear = action
        }
        return view
    }

    /// Gives the text field a default style.
    /// - Parameters:
    ///   - height: How tall the text field should be, in points. Defaults to 58.
    ///   - backgroundColor: The background color of the text field. Defaults to clear.
    ///   - accentColor: The cursor and highlighting color of the text field. Defaults to light blue.
    ///   - inputFont: The font of the text field
    ///   - paddingLeading: Leading-edge padding size, in points. Defaults to 25.
    ///   - cornerRadius: Text field corner radius. Defaults to 6.
    ///   - hasShadow: Whether or not the text field has a shadow when selected. Defaults to true.
    /// - Returns: A stylized view containing a text field.
    func style(height: CGFloat = 58,
               backgroundColor: Color? = nil,
               accentColor: Color = Color(red: 0.30, green: 0.76, blue: 0.85),
               font inputFont: UIFont? = nil,
               paddingLeading: CGFloat = 25,
               cornerRadius: CGFloat = 6,
               hasShadow: Bool = true,
               image: Image? = nil) -> some View {
        var darkMode: Bool { colorScheme == .dark }

        let cursorColor: Color = accentColor
        let height: CGFloat = height
        let leadingPadding: CGFloat = paddingLeading

        var backgroundGray: Double { darkMode ? 0.25 : 0.95 }

        var finalBGColor: Color {
            if let backgroundColor {
                return backgroundColor
            }
            return .init(white: backgroundGray)
        }

        var shadowOpacity: Double { (designEditing && hasShadow) ? 0.5 : 0 }
        var shadowGray: Double { darkMode ? 0.8 : 0.5 }
        var shadowColor: Color { Color(white: shadowGray).opacity(shadowOpacity) }

        var borderColor: Color {
            designEditing && darkMode ? .init(white: 0.6) : .clear
        }

        var font: UIFont {
            if let inputFont {
                return inputFont
            } else {
                let fontSize: CGFloat = 20
                let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
                if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                    return UIFont(descriptor: descriptor, size: fontSize)
                } else {
                    return systemFont
                }
            }
        }

        return ZStack {
            HStack {
                if let image {
                    image
                }
                self
                    .accentColor(cursorColor)
                    .fontFromUIFont(font)
            }
            .padding(.horizontal, leadingPadding)
        }
        .frame(height: height)
        .background(finalBGColor)
        .cornerRadius(cornerRadius)
        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(borderColor))
        .padding(.horizontal, leadingPadding)
        .shadow(color: shadowColor, radius: 5, x: 0, y: 4)
    }
}
