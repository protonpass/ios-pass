//
// TextExtensions.swift
// Proton Pass - Created on 09/08/2022.
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

public extension Text {
    init(_ texts: [Text]) {
        self.init(verbatim: "")
        for text in texts {
            // swiftlint:disable:next shorthand_operator
            self = self + text
        }
    }

    func adaptiveForegroundStyle(_ color: Color) -> Text {
        if #available(iOS 17, *) {
            foregroundStyle(color)
        } else {
            // swiftlint:disable:next deprecated_foregroundcolor_modifier
            foregroundColor(color)
        }
    }
}

public enum TextContent {
    case verbatim(String)
    case localized(LocalizedStringKey)
}

public extension Text {
    init(_ content: TextContent) {
        switch content {
        case let .verbatim(value):
            self.init(verbatim: value)
        case let .localized(value):
            self.init(value)
        }
    }
}
