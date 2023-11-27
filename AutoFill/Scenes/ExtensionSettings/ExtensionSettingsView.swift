//
// ExtensionSettingsView.swift
// Proton Pass - Created on 05/04/2023.
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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct ExtensionSettingsView: View {
    @StateObject var viewModel: ExtensionSettingsViewModel
    private let theme = resolve(\SharedToolingContainer.theme)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    OptionRow(height: .medium) {
                        Toggle(isOn: $viewModel.quickTypeBar) {
                            Text("QuickType bar suggestions")
                                .foregroundColor(Color(uiColor: PassColor.textNorm))
                        }
                        .tint(Color(uiColor: PassColor.interactionNorm))
                    }
                    .roundedEditableSection()
                    Text("Quickly pick a login item from suggestions above the keyboard")
                        .sectionTitleText()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                        .frame(height: 24)

                    OptionRow(height: .medium) {
                        Toggle(isOn: $viewModel.automaticallyCopyTotpCode) {
                            Text("Copy 2FA code")
                                .foregroundColor(Color(uiColor: PassColor.textNorm))
                        }
                        .tint(Color(uiColor: PassColor.interactionNorm))
                    }
                    .roundedEditableSection()

                    Spacer()
                }
                .padding(.horizontal)
            }
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationTitle("AutoFill")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: viewModel.dismiss)
                }
            }
        }
        .navigationViewStyle(.stack)
        .theme(theme)
        .localAuthentication(delayed: false,
                             onAuth: {},
                             onSuccess: {},
                             onFailure: viewModel.logOut)
    }
}
