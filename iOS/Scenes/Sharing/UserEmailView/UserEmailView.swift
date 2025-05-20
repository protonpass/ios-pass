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

import DesignSystem
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct UserEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserEmailViewModel()
    @StateObject private var router = resolve(\RouterContainer.sharingRouter)
    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Share with")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.horizontal, DesignConstant.sectionPadding)

            VStack(alignment: .leading) {
                if case let .new(vault, _) = viewModel.element {
                    vaultRow(vault)
                }

                AnyLayout(FlowLayout(spacing: 8)) {
                    ForEach(viewModel.selectedEmails + [""], id: \.self) { item in
                        token(for: item)
                    }
                }
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
                    InviteSuggestionsSection(selectedEmails: viewModel.selectedEmails,
                                             recommendations: recommendations,
                                             isFetchingMore: viewModel.isFetchingMore,
                                             displayCounts: Bundle.main.isQaBuild,
                                             onSelect: { viewModel.handleSelection(suggestedEmail: $0) },
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .routingProvided
        .navigationStackEmbeded($router.path)
        .environmentObject(router)
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

    @ViewBuilder
    var emailTextField: some View {
        let placeholder = #localized("Email address")
        let maxCharCount = max(placeholder.count, viewModel.email.count)
        BackspaceAwareTextField(text: $viewModel.email,
                                isFocused: $isFocused,
                                config: .init(font: .body,
                                              placeholder: placeholder,
                                              autoCapitalization: .none,
                                              autoCorrection: .no,
                                              keyboardType: .emailAddress,
                                              returnKeyType: .default,
                                              textColor: PassColor.textNorm,
                                              tintColor: PassColor.interactionNorm),
                                onBackspace: { viewModel.highlightLastEmail() },
                                onReturn: { _ = viewModel.appendCurrentEmail() })
            .frame(width: max(150, CGFloat(maxCharCount) * 10), height: 32)
            .clipped()
    }

    @ViewBuilder
    func emailCell(for email: String) -> some View {
        let highlighted = viewModel.highlightedEmail == email
        let invalid = viewModel.invalidEmails.contains(email)

        let textColor: () -> UIColor = {
            switch (highlighted, invalid) {
            case (false, true):
                PassColor.passwordInteractionNormMajor1
            case (true, _):
                PassColor.textInvert
            default:
                PassColor.textNorm
            }
        }

        let backgroundColor: () -> UIColor = {
            switch (highlighted, invalid) {
            case (true, true):
                PassColor.passwordInteractionNormMajor1
            case (true, false):
                PassColor.interactionNormMajor2
            case (false, true):
                PassColor.passwordInteractionNormMinor1
            default:
                PassColor.interactionNormMinor1
            }
        }

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
        .foregroundStyle(textColor().toColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(backgroundColor().toColor)
        .cornerRadius(9)
        .animation(.default, value: highlighted)
        .animation(.default, value: invalid)
        .contentShape(.rect)
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
    func vaultRow(_ vault: VaultContent) -> some View {
        HStack(spacing: 16) {
            VaultRow(thumbnail: {
                         CircleButton(icon: vault.display.icon.icon.bigImage,
                                      iconColor: vault.display.color.color.color,
                                      backgroundColor: vault.display.color.color.color
                                          .withAlphaComponent(0.16))
                     },
                     title: vault.name,
                     itemCount: 1,
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
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close") {
                viewModel.resetShareInviteInformation()
                dismiss()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isChecking {
                ProgressView()
            } else {
                DisablableCapsuleTextButton(title: #localized("Continue"),
                                            titleColor: PassColor.textInvert,
                                            disableTitleColor: PassColor.textHint,
                                            backgroundColor: PassColor.interactionNormMajor1,
                                            disableBackgroundColor: PassColor.interactionNormMinor1,
                                            disabled: !viewModel.canContinue,
                                            action: {
                                                isFocused = false
                                                Task {
                                                    if await viewModel.continue() {
                                                        router.navigate(to: .userSharePermission)
                                                    }
                                                }
                                            })
            }
        }
    }
}

#Preview("UserEmailView Preview") {
    UserEmailView()
}
