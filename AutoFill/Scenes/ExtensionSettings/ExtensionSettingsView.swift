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
    @StateObject private var viewModel = ExtensionSettingsViewModel()

    private let onDismiss: () -> Void
    private let onLogOut: () -> Void

    init(onDismiss: @escaping () -> Void,
         onLogOut: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onLogOut = onLogOut
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    OptionRow(height: .medium) {
                        StaticToggle("QuickType bar suggestions",
                                     isOn: viewModel.quickTypeBar,
                                     action: { viewModel.toggleQuickTypeBar() })
                    }
                    .roundedEditableSection()
                    Text("Quickly pick a login item from suggestions above the keyboard")
                        .sectionTitleText()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                        .frame(height: 24)

                    OptionRow(height: .medium) {
                        StaticToggle("Copy 2FA code",
                                     isOn: viewModel.automaticallyCopyTotpCode,
                                     action: { viewModel.toggleAutomaticCopy2FACode() })
                    }
                    .roundedEditableSection()

                    if viewModel.showAutomaticCopyTotpCodeExplication {
                        Text("Automatic copy of the 2FA code requires biometric lock or PIN code to be set up")
                            .sectionTitleText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            .background(PassColor.backgroundNorm.toColor)
            .animation(.default, value: viewModel.showAutomaticCopyTotpCodeExplication)
            .navigationTitle("AutoFill")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: onDismiss)
                }
            }
        }
        .localAuthentication(onFailure: onLogOut)
    }
}
