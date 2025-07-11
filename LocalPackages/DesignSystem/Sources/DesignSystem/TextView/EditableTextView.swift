//
// EditableTextView.swift
// Proton Pass - Created on 26/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public struct TextViewConfiguration: Sendable {
    public let minWidth: CGFloat
    public let minHeight: CGFloat
    public let font: UIFont
    public let textColor: UIColor

    public init(minWidth: CGFloat = 300,
                // 0 means taking the minimal height for displaying the text view
                minHeight: CGFloat = 0,
                font: UIFont = .body,
                textColor: UIColor = PassColor.textNorm) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.font = font
        self.textColor = textColor
    }
}

/// `UITextView` wrapper that automatically adjusts its height depending on the content
struct EditableTextView: UIViewRepresentable {
    @Binding var text: String
    private let config: TextViewConfiguration
    private let textViewDidChange: ((String) -> Void)?

    init(text: Binding<String>,
         config: TextViewConfiguration = .init(),
         textViewDidChange: ((String) -> Void)? = nil) {
        _text = text
        self.config = config
        self.textViewDidChange = textViewDidChange
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = text
        view.font = config.font
        view.backgroundColor = .clear
        view.textColor = config.textColor
        view.isEditable = true
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Preserve cursor position and scroll offset
        let selectedRange = textView.selectedRange
        let contentOffset = textView.contentOffset

        // Update text and properties
        textView.text = text
        textView.font = config.font
        textView.textColor = config.textColor

        // Restore cursor position and scroll offset
        textView.selectedRange = selectedRange
        textView.contentOffset = contentOffset
        // Ensure cursor is visible
        if let selectedTextRange = textView.selectedTextRange {
            let caretRect = textView.caretRect(for: selectedTextRange.end)
            textView.scrollRectToVisible(caretRect, animated: false)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize,
                      uiView: UITextView,
                      context: Context) -> CGSize? {
        let width = proposal.width ?? config.minWidth
        let size = uiView.sizeThatFits(CGSize(width: width, height: 0))
        return CGSize(width: width, height: max(config.minHeight, size.height))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: EditableTextView

        init(_ parent: EditableTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.textViewDidChange?(textView.text)
        }
    }
}

public struct EditableTextViewWithPlaceholder: View {
    @State private var showPlaceholder: Bool
    @Binding var text: String
    private let config: TextViewConfiguration
    private let placeholder: String
    private let placerholderColor: UIColor

    public init(text: Binding<String>,
                config: TextViewConfiguration = .init(),
                placeholder: String,
                placerholderColor: UIColor = PassColor.textWeak) {
        _showPlaceholder = .init(initialValue: text.wrappedValue.isEmpty)
        _text = text
        self.config = config
        self.placeholder = placeholder
        self.placerholderColor = placerholderColor
    }

    public var body: some View {
        EditableTextView(text: $text,
                         config: config,
                         textViewDidChange: { showPlaceholder = $0.isEmpty })
            .background(Text(verbatim: placeholder)
                .foregroundStyle(placerholderColor.toColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .opacity(showPlaceholder ? 1 : 0))
    }
}
