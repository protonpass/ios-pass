//
// ItemTypeFilterButton.swift
// Proton Pass - Created on 31/07/2023.
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
import SwiftUI
import UIComponents

struct ItemTypeFilterButton: View {
    let itemCount: ItemCount
    let selectedOption: ItemTypeFilterOption
    /// Applicable to platforms other than iOS
    let onSelect: (ItemTypeFilterOption) -> Void
    /// Applicable to iOS only
    let onTap: () -> Void

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            Button(action: onTap) {
                let uiModel = selectedOption.uiModel(from: itemCount)
                text(for: uiModel)
                    .font(.callout.weight(.medium))
                    .foregroundColor(PassColor.interactionNormMajor2.toColor)
            }
        } else {
            menu
        }
    }
}

private extension ItemTypeFilterButton {
    var menu: some View {
        Menu(content: {
            ForEach(ItemTypeFilterOption.allCases, id: \.self) { option in
                let uiModel = option.uiModel(from: itemCount)
                Button(action: {
                    onSelect(option)
                }, label: {
                    Label(title: {
                        text(for: uiModel)
                    }, icon: {
                        if option == selectedOption {
                            Image(systemName: "checkmark")
                        }
                    })
                })
                // swiftformat:disable:next isEmpty
                .disabled(uiModel.count == 0) // swiftlint:disable:this empty_count
            }
        }, label: {
            let uiModel = selectedOption.uiModel(from: itemCount)
            text(for: uiModel)
                .font(.callout.weight(.medium))
                .foregroundColor(PassColor.interactionNormMajor2.toColor)
        })
        .animationsDisabled()
    }

    func text(for uiModel: ItemTypeFilterOptionUiModel) -> some View {
        Text("\(uiModel.title) (\(uiModel.count))")
    }
}
