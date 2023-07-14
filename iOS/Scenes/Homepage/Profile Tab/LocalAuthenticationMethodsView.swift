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

import Factory
import SwiftUI
import UIComponents

struct LocalAuthenticationMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    private let selectedMethod: LocalAuthenticationMethod
    private let uiModels: [LocalAuthenticationMethodUiModel]
    private let onSelect: (LocalAuthenticationMethodUiModel) -> Void

    init(supportedMethods: [LocalAuthenticationMethodUiModel],
         onSelect: @escaping (LocalAuthenticationMethodUiModel) -> Void) {
        let preferences = resolve(\SharedToolingContainer.preferences)
        selectedMethod = preferences.localAuthenticationMethod
        uiModels = supportedMethods
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationView {
            VStack {
                ForEach(uiModels, id: \.method) { uiModel in
                    title(for: uiModel)
                    PassSectionDivider()
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Lock with")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private extension LocalAuthenticationMethodsView {
    func title(for uiModel: LocalAuthenticationMethodUiModel) -> some View {
        OptionRow(action: {
                      onSelect(uiModel)
                      dismiss()
                  },
                  height: .compact,
                  horizontalPadding: 0,
                  content: {
                      Label(title: {
                          Text(uiModel.title)
                              .frame(maxWidth: .infinity, alignment: .leading)
                      }, icon: {
                          if uiModel.method == selectedMethod {
                              Image(systemName: "checkmark")
                          }
                      })
                      .labelStyle(.rightIcon)
                      .foregroundColor(uiModel.method == selectedMethod ?
                          PassColor.interactionNorm.toColor : PassColor.textNorm.toColor)
                  })
    }
}
