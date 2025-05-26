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

/// `UITextView` wrapper that automatically adjusts its height depending on the content
public struct EditableTextView: UIViewRepresentable {
    @Binding var text: String
    let minWidth: CGFloat
    let minHeight: CGFloat
    let font: UIFont
    let textColor: UIColor

    public init(text: Binding<String>,
                minWidth: CGFloat = 300,
                minHeight: CGFloat = 100,
                font: UIFont = .body,
                textColor: UIColor = PassColor.textNorm) {
        _text = text
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.font = font
        self.textColor = textColor
    }

    public func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.font = font
        view.backgroundColor = .clear
        view.textColor = textColor
        view.isEditable = true
        view.isScrollEnabled = false
        view.delegate = context.coordinator
        return view
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    public func sizeThatFits(_ proposal: ProposedViewSize,
                             uiView: UITextView,
                             context: Context) -> CGSize? {
        let width = proposal.width ?? minWidth
        let size = uiView.sizeThatFits(CGSize(width: width, height: 0))
        return CGSize(width: width, height: max(minHeight, size.height))
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        public func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}
