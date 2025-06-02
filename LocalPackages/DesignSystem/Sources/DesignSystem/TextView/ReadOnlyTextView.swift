//
// ReadOnlyTextView.swift
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

/// `UITextView` wrapper that support data type detections
public struct ReadOnlyTextView: UIViewRepresentable {
    let text: String
    let textColor: UIColor
    let font: UIFont
    let minWidth: CGFloat
    let maxHeight: CGFloat
    let dataDetectorTypes: UIDataDetectorTypes
    let onRenderCompletion: ((_ isTrimmed: Bool) -> Void)?

    public init(_ text: String,
                textColor: UIColor = PassColor.textNorm,
                font: UIFont = .body,
                minWidth: CGFloat = 300,
                maxHeight: CGFloat = .greatestFiniteMagnitude,
                dataDetectorTypes: UIDataDetectorTypes = .all,
                onRenderCompletion: ((_ isTrimmed: Bool) -> Void)? = nil) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.minWidth = minWidth
        self.maxHeight = maxHeight
        self.dataDetectorTypes = dataDetectorTypes
        self.onRenderCompletion = onRenderCompletion
    }

    public func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.font = font
        view.backgroundColor = .clear
        view.textColor = textColor
        view.isEditable = false
        view.isScrollEnabled = false
        view.dataDetectorTypes = dataDetectorTypes
        view.textContainerInset = .zero
        return view
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
    }

    public func sizeThatFits(_ proposal: ProposedViewSize,
                             uiView: UITextView,
                             context: Context) -> CGSize? {
        let width = proposal.width ?? minWidth
        let calculatedSize = uiView.sizeThatFits(CGSize(width: width,
                                                        height: CGFloat.greatestFiniteMagnitude))
        onRenderCompletion?(calculatedSize.height > maxHeight)
        let finalHeight = min(calculatedSize.height, maxHeight)
        return CGSize(width: width, height: finalHeight)
    }
}
