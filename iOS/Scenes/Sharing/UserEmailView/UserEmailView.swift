//
//
// UserEmailView.swift
// Proton Pass - Created on 19/07/2023.
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
//

import Client
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct UserEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserEmailViewModel()
    private var router = resolve(\RouterContainer.mainNavViewRouter)
    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Share with")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(PassColor.textNorm.toColor)
                .padding(.horizontal, DesignConstant.sectionPadding)

            VStack(alignment: .leading) {
                if case let .new(vault, _) = viewModel.vault {
                    vaultRow(vault)
                }

                FlowLayout(mode: .scrollable,
                           items: viewModel.selectedEmails + [""],
                           viewMapping: { token(for: $0) })
                    .padding(.leading, -4)

                PassDivider()
                    .padding(.horizontal, -DesignConstant.sectionPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                if viewModel.recommendationsState == .loading {
                    VStack {
                        Spacer(minLength: 150)
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if let recommendations = viewModel.recommendationsState.recommendations,
                          !recommendations.isEmpty {
                    InviteSuggestionsSection(selectedEmails: $viewModel.selectedEmails,
                                             recommendations: recommendations,
                                             isFetchingMore: viewModel.isFetchingMore,
                                             displayCounts: Bundle.main.isQaBuild,
                                             onLoadMore: {
                                                 viewModel
                                                     .updateRecommendations(removingCurrentRecommendations: false)
                                             })
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignConstant.sectionPadding)
            .scrollViewEmbeded(maxWidth: .infinity)
        }
        .onAppear {
            isFocused = true
        }
        .onChange(of: viewModel.highlightedEmail) { highlightedEmail in
            isFocused = highlightedEmail == nil
        }
        .animation(.default, value: viewModel.selectedEmails)
        .animation(.default, value: viewModel.recommendationsState)
        .navigate(isActive: $viewModel.goToNextStep,
                  destination: router.navigate(to: .userSharePermission))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .navigationStackEmbeded()
        .ignoresSafeArea(.keyboard)
    }
}

private extension UserEmailView {
    @ViewBuilder
    func token(for email: String) -> some View {
        if email.isEmpty {
            emailTextField
        } else {
            emailCell(for: email)
        }
    }

    var emailTextField: some View {
        BackspaceAwareTextField(text: $viewModel.email,
                                isFocused: $isFocused,
                                config: .init(font: .body,
                                              placeholder: #localized("Email address"),
                                              autoCapitalization: .none,
                                              autoCorrection: .no,
                                              keyboardType: .emailAddress,
                                              returnKeyType: .default,
                                              textColor: PassColor.textNorm,
                                              tintColor: PassColor.interactionNorm),
                                onBackspace: { viewModel.highlightLastEmail() },
                                onReturn: { _ = viewModel.appendCurrentEmail() })
            .frame(width: max(150, CGFloat(viewModel.email.count) * 10), height: 32)
            .clipped()
    }

    @ViewBuilder
    func emailCell(for email: String) -> some View {
        let highlighted = viewModel.highlightedEmail == email
        let focused: Binding<Bool> = .init(get: {
            highlighted
        }, set: { newValue in
            if !newValue {
                viewModel.highlightedEmail = nil
            }
        })

        HStack(alignment: .center, spacing: 10) {
            Text(email)
                .lineLimit(1)
        }
        .font(.callout)
        .foregroundColor(highlighted ? PassColor.textInvert.toColor : PassColor.textNorm.toColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(highlighted ?
            PassColor.interactionNormMajor2.toColor : PassColor.interactionNormMinor1.toColor)
        .cornerRadius(9)
        .animation(.default, value: highlighted)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleHighlight(email) }
        .overlay {
            // Dummy invisible text field to allow removing a token with backspace
            BackspaceAwareTextField(text: .constant(""),
                                    isFocused: focused,
                                    config: .init(font: .title,
                                                  placeholder: "",
                                                  autoCapitalization: .none,
                                                  autoCorrection: .no,
                                                  keyboardType: .emailAddress,
                                                  returnKeyType: .default,
                                                  textColor: .clear,
                                                  tintColor: .clear),
                                    onBackspace: { viewModel.deselect(email) },
                                    onReturn: { viewModel.toggleHighlight(email) })
                .opacity(0)
        }
    }
}

private extension UserEmailView {
    func vaultRow(_ vault: VaultProtobuf) -> some View {
        HStack(spacing: 16) {
            VaultRow(thumbnail: {
                         CircleButton(icon: vault.display.icon.icon.bigImage,
                                      iconColor: vault.display.color.color.color,
                                      backgroundColor: vault.display.color.color.color
                                          .withAlphaComponent(0.16))
                     },
                     title: vault.name,
                     itemCount: 1,
                     isShared: false,
                     isSelected: false,
                     maxWidth: nil,
                     height: 74)

            CircleButton(icon: IconProvider.pencil,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: { viewModel.customizeVault() })
        }
        .padding(.horizontal, 16)
        .roundedEditableSection()
    }
}

private extension UserEmailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1) {
                viewModel.resetShareInviteInformation()
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isChecking {
                ProgressView()
            } else {
                DisablableCapsuleTextButton(title: #localized("Continue"),
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: !viewModel.canContinue,
                                            action: { viewModel.continue() })
            }
        }
    }
}

#Preview("UserEmailView Preview") {
    UserEmailView()
}
