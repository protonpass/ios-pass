//
// EditThemeView.swift
// Proton Pass - Created on 31/03/2023.
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
import Entities
import SwiftUI

struct EditThemeView: View {
    @Environment(\.dismiss) private var dismiss
    let currentTheme: Theme
    let onSelect: (Theme) -> Void

    var body: some View {
        VStack {
            Text("Theme")
                .navigationTitleText()

            ForEach(Theme.allCases) { theme in
                SelectableOptionRow(action: { onSelect(theme); dismiss() },
                                    height: .compact,
                                    content: {
                                        Label(title: {
                                            Text(theme.description)
                                        }, icon: {
                                            Image(uiImage: theme.icon)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: 20, maxHeight: 20)
                                        })
                                        .foregroundStyle(PassColor.textNorm)
                                    },
                                    isSelected: theme == currentTheme)

                if theme != Theme.allCases.last {
                    PassDivider()
                }
            }
        }
        .padding()
        .background(PassColor.backgroundWeak)
        .fittedPresentationDetent()
    }
}
