//
// LogInDetailView.swift
// Proton Pass - Created on 07/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct LogInDetailView: View {
    @StateObject private var viewModel: LogInDetailViewModel
    @State private var isShowingPassword = false
    @Namespace private var bottomID

    private var iconTintColor: UIColor { viewModel.itemContent.type.normColor }

    init(viewModel: LogInDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.isShownAsSheet {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
        } else {
            realBody
        }
    }

    private var realBody: some View {
        VStack {
            ScrollViewReader { value in
                ScrollView {
                    VStack(spacing: 0) {
                        ItemDetailTitleView(itemContent: viewModel.itemContent,
                                            vault: viewModel.vault?.vault,
                                            shouldShowVault: viewModel.shouldShowVault)
                            .padding(.bottom, 40)

                        usernamePassword2FaSection

                        if !viewModel.urls.isEmpty {
                            urlsSection
                                .padding(.top, 8)
                        }

                        if !viewModel.itemContent.note.isEmpty {
                            NoteDetailSection(itemContent: viewModel.itemContent,
                                              vault: viewModel.vault?.vault)
                                .padding(.top, 8)
                        }

                        CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                            uiModels: viewModel.customFieldUiModels,
                                            isFreeUser: viewModel.isFreeUser,
                                            onSelectHiddenText: { copyHiddenText($0) },
                                            onSelectTotpToken: { copyTOTPToken($0) },
                                            onUpgrade: { viewModel.upgrade() })

                        ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                                 itemHistoryEnable: viewModel.itemHistoryEnabled,
                                                 action: { viewModel.showItemHistory() })

                        ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                                  itemContent: viewModel.itemContent)
                            .padding(.top, 24)
                            .id(bottomID)
                    }
                    .padding()
                }
                .animation(.default, value: viewModel.moreInfoSectionExpanded)
                .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                    withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
                }
            }

            if viewModel.isAlias {
                viewAliasCard
                    .padding(.horizontal)
            }
        }
        .animation(.default, value: viewModel.moreInfoSectionExpanded)
        .itemDetailSetUp(viewModel)
    }

    private var usernamePassword2FaSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            usernameRow
            PassSectionDivider()
            passwordRow

            switch viewModel.totpTokenState {
            case .loading:
                EmptyView()

            case .notAllowed:
                PassSectionDivider()
                totpNotAllowedRow

            case .allowed:
                if viewModel.totpUri.isEmpty {
                    EmptyView()
                } else {
                    PassSectionDivider()
                    TOTPRow(totpManager: viewModel.totpManager,
                            tintColor: iconTintColor,
                            onCopyTotpToken: { viewModel.copyTotpToken($0) })
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.totpTokenState)
    }

    private var usernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.user,
                                  color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username or email address")
                    .sectionTitleText()

                if viewModel.username.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.username)
                        .sectionContentText()

                    if viewModel.isAlias {
                        Button { viewModel.showAliasDetail() } label: {
                            Text("View alias")
                                .font(.callout)
                                .foregroundColor(Color(uiColor: viewModel.itemContent.type.normMajor2Color))
                                .underline(color: Color(uiColor: viewModel.itemContent.type.normMajor2Color))
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: { viewModel.copyUsername() })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button { viewModel.copyUsername() } label: {
                Text("Copy")
            }

            Button {
                viewModel.showLarge(.text(viewModel.username))
            } label: {
                Text("Show large")
            }
        }
    }

    private var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key, color: iconTintColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.passwordStrength.sectionTitle)
                    .font(.footnote)
                    .foregroundColor(viewModel.passwordStrength.sectionTitleColor)

                if viewModel.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    if isShowingPassword {
                        Text(viewModel.coloredPassword)
                            .font(.body.monospaced())
                    } else {
                        Text(String(repeating: "•", count: 12))
                            .sectionContentText()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.copyPassword() }

            Spacer()

            if !viewModel.password.isEmpty {
                CircleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             action: { isShowingPassword.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button(action: {
                withAnimation {
                    isShowingPassword.toggle()
                }
            }, label: {
                Text(isShowingPassword ? "Conceal" : "Reveal")
            })

            Button { viewModel.copyPassword() } label: {
                Text("Copy")
            }

            Button { viewModel.showLargePassword() } label: {
                Text("Show large")
            }
        }
    }

    private var totpNotAllowedRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA limit reached")
                    .sectionTitleText()
                UpgradeButtonLite { viewModel.upgrade() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    private var urlsSection: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.urls, id: \.self) { url in
                        Button(action: {
                            viewModel.openUrl(url)
                        }, label: {
                            Text(url)
                                .foregroundColor(Color(uiColor: viewModel.itemContent.type.normMajor2Color))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        })
                        .contextMenu {
                            Button(action: {
                                viewModel.openUrl(url)
                            }, label: {
                                Text("Open")
                            })

                            Button(action: {
                                viewModel.copyToClipboard(text: url, message: #localized("Website copied"))
                            }, label: {
                                Text("Copy")
                            })
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.default, value: viewModel.urls)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    private var viewAliasCard: some View {
        Group {
            Text("View and edit details for this alias on the separate alias page.")
                .font(.callout)
                .foregroundColor(PassColor.textNorm.toColor) +
                Text(verbatim: " ")
                .font(.callout) +
                Text("View")
                .font(.callout)
                .foregroundColor(viewModel.itemContent.type.normMajor2Color.toColor)
                .underline(color: viewModel.itemContent.type.normMajor2Color.toColor)
        }
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.backgroundMedium.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: viewModel.showAliasDetail)
    }
}

private extension LogInDetailView {
    func copyTOTPToken(_ token: String) {
        viewModel.copyToClipboard(text: token, message: #localized("TOTP copied"))
    }

    func copyHiddenText(_ text: String) {
        viewModel.copyToClipboard(text: text, message: #localized("Hidden text copied"))
    }
}
