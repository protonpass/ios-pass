//
//
// EmailGroupSelectionView.swift
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
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct EmailGroupSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EmailGroupSelectionViewModel()
    @State private var router = PathRouter()
    @State private var isFocused = false

    var body: some View {
        mainContent
            .environmentObject(viewModel)
            .onAppear {
                isFocused = true
            }
            .task {
                await viewModel.loadData()
            }
            .onChange(of: viewModel.highlightedRecommendation) { highlightedRecommendation in
                isFocused = highlightedRecommendation == nil
            }
            .animation(.default, value: viewModel.selectedRecommendations)
            .animation(.default, value: viewModel.loading)
            .padding(.horizontal, DesignConstant.sectionPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundNorm)
            .toolbar { toolbarContent }
            .routingProvided
            .navigationStackEmbeded($router.path)
            .environment(router)
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $viewModel.showGroupMembers,
                   onDismiss: { viewModel.clearHighlightedRecommendation() },
                   content: { if let reco = viewModel.highlightedRecommendation,
                                 case let .group(infos) = reco {
                           GroupUsersInformationView(groupInfo: infos, rights: nil)
                               .presentationDetents([.medium, .large])
                               .presentationDragIndicator(.visible)
                       }
                   })
    }
}

// MARK: - Internal views

private extension EmailGroupSelectionView {
    var mainContent: some View {
        VStack(alignment: .leading) {
            title

            VStack(alignment: .leading) {
                if case let .new(vault, _) = viewModel.element {
                    vaultRow(vault)
                }

                AnyLayout(FlowLayout(spacing: 8)) {
                    ForEach(viewModel.selectedRecommendations + [.email("")]) { item in
                        token(for: item)
                            .fixedSize()
                    }
                }

                PassDivider()
                    .padding(.horizontal, -DesignConstant.sectionPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                suggestions

                Spacer()
            }
            .scrollViewEmbeded(maxWidth: .infinity)
        }
    }

    var title: some View {
        Text("Share with")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(PassColor.textNorm)
    }

    var suggestions: some View {
        InviteSuggestionsSection()
            .overlay {
                overlayContent
            }
    }

    @ViewBuilder
    var overlayContent: some View {
        if viewModel.loading {
            VStack {
                Spacer(minLength: 150)
                ProgressView()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private extension EmailGroupSelectionView {
    @ViewBuilder
    func token(for recommendation: InviteRecommendationType) -> some View {
        if recommendation.name.isEmpty {
            emailTextField
        } else {
            recommendationCell(for: recommendation)
        }
    }

    @ViewBuilder
    var emailTextField: some View {
        let placeholder = #localized("Email address")
        let width = max(150, CGFloat(max(placeholder.count, viewModel.email.count)) * 10)
        BackspaceAwareTextField(text: $viewModel.email,
                                isFocused: $isFocused,
                                config: .init(font: .body,
                                              placeholder: placeholder,
                                              textColor: PassUIColor.textNorm,
                                              tintColor: PassUIColor.interactionNorm),
                                onBackspace: { viewModel.highlightLast() },
                                onReturn: { _ = viewModel.appendCurrentEmail() })
            .frame(width: width, height: 32)
            .clipped()
    }

    @ViewBuilder
    func recommendationCell(for reco: InviteRecommendationType) -> some View {
        let highlighted = viewModel.highlightedRecommendation == reco
        let invalid = viewModel.invalidEmails.contains(reco.name)

        let textColor: () -> Color = {
            switch (highlighted, invalid) {
            case (false, true):
                PassColor.passwordInteractionNormMajor1
            case (true, _):
                PassColor.textInvert
            default:
                PassColor.textNorm
            }
        }

        let backgroundColor: () -> Color = {
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
                viewModel.highlightedRecommendation = nil
            }
        })

        HStack(alignment: .center, spacing: 10) {
            let name = if reco.isEmail {
                reco.name
            } else {
                if let memberCount = reco.memberCount {
                    "\(reco.name) (\(memberCount))"
                } else {
                    reco.name
                }
            }
            Text(name)
                .lineLimit(1)
                .truncationMode(.tail) // ellipsis if too long
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(.callout)
        .foregroundStyle(textColor())
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(backgroundColor())
        .cornerRadius(9)
        .animation(.default, value: highlighted)
        .animation(.default, value: invalid)
        .contentShape(.rect)
        .onTapGesture { viewModel.toggleHighlight(reco) }
        .overlay {
            // Dummy invisible text field to allow removing a token with backspace
            BackspaceAwareTextField(text: .constant(""),
                                    isFocused: focused,
                                    config: .init(font: .title,
                                                  placeholder: "",
                                                  textColor: .clear,
                                                  tintColor: .clear),
                                    onBackspace: { viewModel.deselect(reco) },
                                    onReturn: { viewModel.toggleHighlight(reco) })
                .opacity(0)
        }
    }
}

private extension EmailGroupSelectionView {
    func vaultRow(_ vault: VaultContent) -> some View {
        HStack(spacing: 16) {
            VaultRow(thumbnail: {
                         CircleButton(icon: vault.display.icon.icon.bigImage,
                                      iconColor: vault.display.color.color.color,
                                      backgroundColor: vault.display.color.color.color.opacity(0.16))
                     },
                     title: vault.name,
                     itemCount: 1,
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

private extension EmailGroupSelectionView {
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

// MARK: - Subviews

struct GroupUsersInformationView: View {
    let groupInfo: GroupInfo
    let rights: String?

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            Text(verbatim: "\(groupInfo.group.name)")
                .foregroundStyle(PassColor.textNorm)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)

            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(groupInfo.members ?? []) { member in
                        if let email = member.email {
                            HStack(spacing: DesignConstant.sectionPadding) {
                                ZStack {
                                    PassColor.interactionNormMinor1
                                        .clipShape(RoundedRectangle(cornerRadius: 40 / 2.5, style: .continuous))
                                    Text(String(email.prefix(2).uppercased()))
                                        .font(.system(size: 40 / 3))
                                        .fontWeight(.medium)
                                        .foregroundStyle(PassColor.interactionNormMajor2)
                                }
                                .frame(width: 40, height: 40)

                                VStack {
                                    Text(email)
                                        .foregroundStyle(PassColor.textNorm)
                                        .lineLimit(1)
                                    if let rights {
                                        Text(rights)
                                            .foregroundStyle(PassColor.textWeak)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .contentShape(.rect)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.top, 32)
        .background(PassColor.backgroundNorm)
    }
}

#Preview("UserEmailView Preview") {
    EmailGroupSelectionView()
}
