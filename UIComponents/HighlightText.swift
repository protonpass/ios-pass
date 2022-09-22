//
// HighlightText.swift
// Proton Pass - Created on 22/09/2022.
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

public protocol HighlightableText {
    var fullText: String { get }
    var highlightText: String? { get }
    var isLeadingText: Bool { get }
    var isTrailingText: Bool { get }
}

public struct HighlightText: View {
    public let text: HighlightableText

    public init(text: HighlightableText) {
        self.text = text
    }

    public var body: some View {
        let leadingString = text.isLeadingText ? "" : "..."
        let trailingString = text.isTrailingText ? "" : "..."

        if let highlightText = text.highlightText {
            let texts = text.fullText.components(separatedBy: highlightText)
            Text(leadingString + (texts.first ?? "")) +
            Text(highlightText)
                .fontWeight(.bold) +
            Text((texts.last ?? "") + trailingString)
        } else {
            Text(leadingString + text.fullText + trailingString)
        }
    }
}
