//
//
// AddCustomEmailView.swift
// Proton Pass - Created on 18/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct AddCustomEmailView: View {
    @StateObject var viewModel: AddCustomEmailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if !viewModel.email.isEmpty, viewModel.isMonitored {
                Text("We’ve sent a verification code to \(viewModel.email). Please enter it below:")
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                TextField("Code", text: $viewModel.code)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .tint(PassColor.interactionNorm.toColor)
                    .frame(height: 64)

                if viewModel.canResendCode {
                    Text("Resend code in \(viewModel.timeRemaining)")
                        .font(.body)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        Button {
                            viewModel.sendVerificationCode()
                        } label: {
                            Text("Resend Code")
                                .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                                .padding()
                        }
                        .buttonStyle(.plain)
                        .roundedDetailSection(backgroundColor: PassColor.interactionNormMinor1,
                                              borderColor: .clear)
                        Spacer()
                    }
                }
            } else {
                TextField("Email address", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .tint(PassColor.interactionNorm.toColor)
                    .frame(height: 64)
            }
            Spacer()
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm.toColor)
        .onChange(of: viewModel.finishedVerification) { isVerificationFinished in
            guard isVerificationFinished else {
                return
            }
            dismiss()
        }
        .navigationTitle(viewModel.isMonitored ? "Confirm your email" : "Custom email monitoring")
        .navigationStackEmbeded()
    }
}

private extension AddCustomEmailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button { viewModel.nextStep() } label: {
                Text("Continue")
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
            }
            .buttonStyle(.plain)
            .background(PassColor.interactionNormMinor1.toColor)
            .clipShape(Capsule())
            .disabled(!viewModel.canContinue)
        }
    }
}
