//
// SetPINCodeView.swift
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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct SetPINCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @StateObject private var viewModel: SetPINCodeViewModel = .init()

    init() {}

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.state.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(PassColor.textNorm.toColor)

                Text(viewModel.state.description)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)

                SecureField(viewModel.state.placeholder,
                            text: viewModel.state == .definition ?
                                $viewModel.definedPIN : $viewModel.confirmedPIN)
                    .keyboardType(.numberPad)
                    .font(.title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .padding(.top, 50)
                    .focused($isFocused)

                if let error = viewModel.error {
                    Text(error.description)
                        .foregroundStyle(PassColor.signalDanger.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .background(PassColor.backgroundNorm.toColor)
            .animation(.default, value: viewModel.error)
            .toolbar { toolbarContent }
            .onAppear {
                isFocused = true
            }
        }
        .accentColor(PassColor.interactionNormMajor1.toColor)
        .tint(PassColor.interactionNormMajor1.toColor)
    }
}

private extension SetPINCodeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: viewModel.state.actionTitle,
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: viewModel.actionNotAllowed,
                                        action: { viewModel.action() })
        }
    }
}
