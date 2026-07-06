//
// LabeledMenuPicker.swift
// Proton Pass - Created on 02/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

struct LabeledMenuPicker<Value: Hashable & Identifiable>: View {
    let title: LocalizedStringKey
    @Binding var selection: Value
    let options: [Value]
    let optionLabel: (Value) -> Text

    var body: some View {
        HStack {
            Text(title, bundle: .module)
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Menu {
                ForEach(options) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            optionLabel(option)
                            Spacer()
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    optionLabel(selection)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    IconProvider.chevronDownFilled
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textHint)
                        .frame(width: 16)
                }
            }
        }
    }
}
