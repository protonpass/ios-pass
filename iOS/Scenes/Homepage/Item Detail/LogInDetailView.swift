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
                                            onSelectHiddenText: copyHiddenText,
                                            onSelectTotpToken: copyTOTPToken,
                                            onUpgrade: viewModel.upgrade)

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
        VStack(spacing: kItemDetailSectionPadding) {
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
                switch viewModel.totpManager.state {
                case .empty:
                    EmptyView()
                default:
                    PassSectionDivider()
                    totpAllowedRow
                }
            }
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.totpTokenState)
    }

    private var usernameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.user,
                                  color: iconTintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Username or email address")
                    .sectionTitleText()

                if viewModel.username.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.username)
                        .sectionContentText()

                    if viewModel.isAlias {
                        Button(action: viewModel.showAliasDetail) {
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
            .onTapGesture(perform: viewModel.copyUsername)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .contextMenu {
            Button(action: viewModel.copyUsername) {
                Text("Copy")
            }

            Button(action: {
                viewModel.showLarge(.text(viewModel.username))
            }, label: {
                Text("Show large")
            })
        }
    }

    private var passwordRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key, color: iconTintColor)
            }

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
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
            .onTapGesture(perform: viewModel.copyPassword)

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
        .padding(.horizontal, kItemDetailSectionPadding)
        .contextMenu {
            Button(action: {
                withAnimation {
                    isShowingPassword.toggle()
                }
            }, label: {
                Text(isShowingPassword ? "Conceal" : "Reveal")
            })

            Button(action: viewModel.copyPassword) {
                Text("Copy")
            }

            Button(action: viewModel.showLargePassword) {
                Text("Show large")
            }
        }
    }

    private var totpNotAllowedRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: iconTintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("2FA limit reached")
                    .sectionTitleText()
                UpgradeButtonLite(action: viewModel.upgrade)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }

    private var totpAllowedRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: iconTintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("2FA token (TOTP)")
                    .sectionTitleText()

                switch viewModel.totpManager.state {
                case .empty:
                    EmptyView()
                case .loading:
                    ProgressView()
                case let .valid(data):
                    TOTPText(code: data.code)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .invalid:
                    Text("Invalid TOTP URI")
                        .font(.caption)
                        .foregroundColor(Color(uiColor: PassColor.signalDanger))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyTotpCode)

            switch viewModel.totpManager.state {
            case let .valid(data):
                TOTPCircularTimer(data: data.timerData)
                    .animation(nil, value: isShowingPassword)
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.totpManager.state)
    }

    private var urlsSection: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth, color: iconTintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
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
        .padding(kItemDetailSectionPadding)
        .roundedDetailSection()
    }

    private var viewAliasCard: some View {
        Group {
            Text("View and edit details for this alias on the separate alias page.")
                .font(.callout)
                .foregroundColor(Color(uiColor: PassColor.textNorm)) +
                Text(verbatim: " ")
                .font(.callout) +
                Text("View")
                .font(.callout)
                .foregroundColor(Color(uiColor: viewModel.itemContent.type.normMajor2Color))
                .underline(color: Color(uiColor: viewModel.itemContent.type.normMajor2Color))
        }
        .padding(kItemDetailSectionPadding)
        .background(Color(uiColor: PassColor.backgroundMedium))
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
