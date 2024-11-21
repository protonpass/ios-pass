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
    func roundedDetailSection(backgroundColor: UIColor = .clear,
                              borderColor: UIColor = PassColor.inputBorderNorm) -> some View {
        background(backgroundColor.toColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.toColor, lineWidth: 1))
    }

    func roundedEditableSection(backgroundColor: UIColor = PassColor.inputBackgroundNorm,
                                borderColor: UIColor = PassColor.inputBorderNorm) -> some View {
        background(backgroundColor.toColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.toColor, lineWidth: 1))
    }
}

public extension Text {
    func editableSectionTitleText(for text: String? = nil,
                                  isValid: Bool = true) -> some View {
        font(.footnote)
            // swiftformat:disable all
            .adaptiveForegroundStyle(isValid ?
                (text?.isEmpty == true ? PassColor.textNorm : PassColor.textWeak).toColor :
                PassColor.signalDanger.toColor)
        // swiftformat:enable all
            .animation(.default, value: isValid)
            .animation(.default, value: text?.isEmpty)
    }

    func sectionTitleText() -> Text {
        font(.footnote)
            .adaptiveForegroundStyle(PassColor.textWeak.toColor)
    }

    func sectionContentText() -> Text {
        adaptiveForegroundStyle(PassColor.textNorm.toColor)
    }

    func sectionHeaderText() -> Text {
        adaptiveForegroundStyle(PassColor.textWeak.toColor)
    }

    /// Used for placeholder `Text`s like `Empty notes`, `No items`...
    func placeholderText() -> Text {
        font(.body.italic()).adaptiveForegroundStyle(PassColor.textWeak.toColor)
    }

    func navigationTitleText() -> Text {
        font(.callout.bold())
            .adaptiveForegroundStyle(PassColor.textNorm.toColor)
    }

    func monitorSectionTitleText(maxWidth: CGFloat? = .infinity) -> some View {
        font(.callout.bold())
            .adaptiveForegroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: maxWidth, alignment: .leading)
    }
}
