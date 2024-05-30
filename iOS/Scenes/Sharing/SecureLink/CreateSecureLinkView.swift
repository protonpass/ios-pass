//
// CreateSecureLinkView.swift
// Proton Pass - Created on 16/05/2024.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateSecureLinkView: View {
    @StateObject private var viewModel: CreateSecureLinkViewModel

    init(viewModel: CreateSecureLinkViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        mainContainer
            .navigationStackEmbeded()
    }
}

private extension CreateSecureLinkView {
    var mainContainer: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            if let link = viewModel.link {
                let uiModel = SecureLinkDetailUiModel(itemContent: viewModel.itemContent,
                                                      url: link.url,
                                                      expirationTime: link.expirationTime,
                                                      readCount: nil,
                                                      maxReadCount: viewModel.readCount.nilIfZero,
                                                      mode: .create)
                SecureLinkDetailView(viewModel: .init(uiModel: uiModel))
            } else {
                createLink
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .showSpinner(viewModel.loading)
        .animation(.default, value: viewModel.link)
        .animation(.default, value: viewModel.readCount)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
    }
}

private extension CreateSecureLinkView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Share Secure Link")
                .navigationTitleText()
        }
    }
}

private extension CreateSecureLinkView {
    var createLink: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            HStack {
                Text("Link expires after")
                    .foregroundStyle(PassColor.textNorm.toColor)

                Spacer()

                Picker("Link expires after", selection: $viewModel.selectedExpiration) {
                    ForEach(SecureLinkExpiration.supportedExpirations) { expiration in
                        Text(expiration.title)
                            .tag(expiration)
                            .fontWeight(.bold)
                    }
                }
                .labelsHidden()
                .padding(4)
                .tint(PassColor.textNorm.toColor)
                .background(PassColor.interactionNormMinor1.toColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            PassDivider()

            Toggle("Restrict number of views", isOn: viewCountBinding)
                .toggleStyle(SwitchToggleStyle.pass)
                .foregroundStyle(PassColor.textNorm.toColor)

            if viewModel.readCount != 0 {
                HStack {
                    Text("Maximum views:")
                    Text(verbatim: "\(viewModel.readCount)")
                        .fontWeight(.bold)
                        .padding(10)
                        .background(PassColor.textDisabled.toColor)
                        .clipShape(.circle)
                    Spacer()
                    Stepper("Maximum views:",
                            value: $viewModel.readCount,
                            in: 1...Int.max,
                            step: 1)
                        .labelsHidden()
                }
                .foregroundStyle(PassColor.textNorm.toColor)
            }

            Spacer()

            CapsuleTextButton(title: "Generate secure link",
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNormMajor1,
                              height: 48,
                              action: { viewModel.createLink() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var viewCountBinding: Binding<Bool> {
        .init(get: {
            viewModel.readCount != 0
        }, set: { newValue in
            viewModel.readCount = newValue ? 1 : 0
        })
    }
}
