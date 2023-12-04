//
// View+ItemDetailModifiers.swift
// Proton Pass - Created on 18/11/2022.
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

public extension View {
    func roundedDetailSection() -> some View {
        overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color(uiColor: PassColor.inputBorderNorm), lineWidth: 1))
    }

    func roundedEditableSection(borderColor: UIColor = PassColor.inputBorderNorm) -> some View {
        background(Color(uiColor: PassColor.inputBackgroundNorm))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.toColor, lineWidth: 1))
    }
}

public extension Text {
    func sectionTitleText(isValid: Bool = true) -> Text {
        font(.footnote)
            .foregroundColor(Color(uiColor: isValid ? PassColor.textWeak : PassColor.signalDanger))
    }

    func sectionContentText() -> Text {
        foregroundColor(Color(uiColor: PassColor.textNorm))
    }

    func sectionHeaderText() -> Text {
        foregroundColor(Color(uiColor: PassColor.textWeak))
    }

    /// Used for placeholder `Text`s like `Empty notes`, `No items`...
    func placeholderText() -> Text {
        font(.body.italic()).foregroundColor(Color(uiColor: PassColor.textWeak))
    }
}
