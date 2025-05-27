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
                minHeight: CGFloat = 100,
                font: UIFont = .body,
                textColor: UIColor = PassColor.textNorm) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.font = font
        self.textColor = textColor
    }
}

/// `UITextView` wrapper that automatically adjusts its height depending on the content
public struct EditableTextView: UIViewRepresentable {
    @Binding var text: String
    let config: TextViewConfiguration
    let textViewDidChange: ((String) -> Void)?

    public init(text: Binding<String>,
                config: TextViewConfiguration = .init(),
                textViewDidChange: ((String) -> Void)? = nil) {
        _text = text
        self.config = config
        self.textViewDidChange = textViewDidChange
    }

    public func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = text
        view.font = config.font
        view.backgroundColor = .clear
        view.textColor = config.textColor
        view.isEditable = true
        view.isScrollEnabled = false
        view.delegate = context.coordinator
        return view
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {}

    public func sizeThatFits(_ proposal: ProposedViewSize,
                             uiView: UITextView,
                             context: Context) -> CGSize? {
        let width = proposal.width ?? config.minWidth
        let size = uiView.sizeThatFits(CGSize(width: width, height: 0))
        return CGSize(width: width, height: max(config.minHeight, size.height))
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        let parent: EditableTextView

        init(_ parent: EditableTextView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            // We don't assign back text here but in `textViewDidEndEditing` instead
            // Because that would trigger a redraw which then causes UI glitches
            parent.textViewDidChange?(textView.text)
        }

        public func textViewDidEndEditing(_ textView: UITextView) {
            parent.$text.wrappedValue = textView.text
        }
    }
}

public struct EditableTextViewWithPlaceholder: View {
    @State private var showPlaceholder: Bool
    @Binding var text: String
    let config: TextViewConfiguration
    let placeholder: String
    let placerholderColor: UIColor

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
                // Heuristic paddings
                .padding(.leading, 4)
                .padding(.top, 8)
                .opacity(showPlaceholder ? 1 : 0))
    }
}
