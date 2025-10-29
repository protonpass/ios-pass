//
// TOTPText.swift
// Proton Pass - Created on 03/02/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import DesignSystem
import SwiftUI

public struct TOTPText: View {
    private let texts: [Text]

    public init(code: String,
                textColor: Color = PassColor.textNorm,
                font: Font = .callout) {
        let segments = Array(code).chunked(into: 3).map { String($0) }
        var texts = [Text]()

        for (index, segment) in segments.enumerated() {
            texts.append(Text(segment)
                .font(font)
                .fontWeight(.medium)
                .adaptiveForegroundStyle(textColor))
            if index != segments.count - 1 {
                texts.append(Text(verbatim: " • ")
                    .font(font)
                    .adaptiveForegroundStyle(PassColor.textHint))
            }
        }
        self.texts = texts
    }

    public var body: some View {
        texts.reduce(into: Text(verbatim: "")) { partialResult, text in
            // swiftlint:disable:next shorthand_operator
            partialResult = partialResult + text
        }
    }
}
