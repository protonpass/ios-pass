//
// SortTypeButton.swift
// Proton Pass - Created on 16/03/2023.
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

import Client
import DesignSystem
import SwiftUI

struct SortTypeButton: View {
    @Binding var selectedSortType: SortType
    let action: () -> Void

    var body: some View {
        if UIDevice.current.isIpad {
            Menu(content: {
                ForEach(SortType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedSortType = type
                    }, label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            if type == selectedSortType {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: sortTypeLabel)
        } else {
            Button(action: action, label: sortTypeLabel)
        }
    }

    private func sortTypeLabel() -> some View {
        Label(selectedSortType.title, systemImage: "arrow.up.arrow.down")
            .font(.callout.weight(.medium))
            .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
            .animationsDisabled()
    }
}
