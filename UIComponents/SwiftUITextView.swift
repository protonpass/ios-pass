//
// SwiftUITextView.swift
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

import SwiftUI

public struct SwiftUITextView: UIViewRepresentable {
    @Binding var text: String
    let textContainerInset: UIEdgeInsets
    let backgroundColor: UIColor
    let onEditingChange: ((Bool) -> Void)?

    public init(text: Binding<String>,
                textContainerInset: UIEdgeInsets = .zero,
                backgroundColor: UIColor = .clear,
                onEditingChange: ((Bool) -> Void)? = nil) {
        self._text = text
        self.textContainerInset = textContainerInset
        self.backgroundColor = backgroundColor
        self.onEditingChange = onEditingChange
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = textContainerInset
        textView.backgroundColor = backgroundColor
        textView.font = .preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.isEditable = onEditingChange != nil
        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
    }

    public func makeCoordinator() -> Coordinator { .init(self) }

    public final class Coordinator: NSObject, UITextViewDelegate {
        let parent: SwiftUITextView

        init(_ parent: SwiftUITextView) {
            self.parent = parent
        }

        public func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onEditingChange?(true)
        }

        public func textViewDidEndEditing(_ textView: UITextView) {
            parent.onEditingChange?(false)
        }

        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
