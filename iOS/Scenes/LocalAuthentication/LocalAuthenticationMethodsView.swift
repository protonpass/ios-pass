//
// LocalAuthenticationMethodsView.swift
// Proton Pass - Created on 13/07/2023.
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
import FactoryKit
import SwiftUI

struct LocalAuthenticationMethodsView: View {
    private let selectedMethod: LocalAuthenticationMethod
    private let uiModels: [LocalAuthenticationMethodUiModel]
    private let onSelect: (LocalAuthenticationMethodUiModel) -> Void

    init(selectedMethod: LocalAuthenticationMethod,
         supportedMethods: [LocalAuthenticationMethodUiModel],
         onSelect: @escaping (LocalAuthenticationMethodUiModel) -> Void) {
        self.selectedMethod = selectedMethod
        uiModels = supportedMethods
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack {
                ForEach(uiModels, id: \.method) { uiModel in
                    let isSelected = uiModel.method == selectedMethod
                    SelectableOptionRow(action: { onSelect(uiModel) },
                                        height: .compact,
                                        content: {
                                            Text(uiModel.title)
                                                .foregroundStyle((isSelected ?
                                                        PassColor.interactionNormMajor2 : PassColor
                                                        .textNorm).toColor)
                                        },
                                        isSelected: isSelected)
                    PassSectionDivider()
                }

                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Unlock with")
                        .navigationTitleText()
                }
            }
        }
    }
}
