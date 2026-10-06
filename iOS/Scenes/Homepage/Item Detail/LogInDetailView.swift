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

import Client
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct LogInDetailView: View {
    @StateObject private var viewModel: LogInDetailViewModel
    @State private var showPassword = false
    @State private var showPenalties = false
    @Namespace private var bottomID

    private var iconTintColor: Color {
        viewModel.itemContent.type.normColor
    }

    init(viewModel: LogInDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            realBody
        }
    }
}

private extension LogInDetailView {
    var realBody: some View {
        VStack {
            ScrollViewReader { value in
                ScrollView {
                    VStack(spacing: 0) {
                        securityIssuesView

                        if let vaultContent = viewModel.shareContent?.share.vaultContent {
                            ItemPathBreadcrumbView(vaultContent: vaultContent, path: viewModel.path)
                        }

                        ItemDetailTitleView(itemContent: viewModel.itemContent,
                                            vault: viewModel.vault?.vault)
                            .padding(.vertical, 16)

                        if !viewModel.passkeys.isEmpty {
                            ForEach(viewModel.passkeys, id: \.keyID) { passkey in
                                PasskeyDetailRow(passkey: passkey,
                                                 onTap: { viewModel.viewPasskey(passkey) })
                                    .padding(.bottom, 8)
                            }
                        }

                        usernamePassword2FaSection

                        if !viewModel.autofillUrls.isEmpty {
                            autofillUrlsSection
                                .padding(.top, 8)
                        }

                        if !viewModel.itemContent.note.isEmpty {
                            NoteDetailSection(itemContent: viewModel.itemContent,
                                              vault: viewModel.vault?.vault)
                                .padding(.top, 8)
                        }

                        CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                            fields: viewModel.customFields,
                                            isFreeUser: viewModel.isFreeUser,
                                            onSelectHiddenText: viewModel.copyHiddenText,
                                            onSelectTotpToken: viewModel.copyTOTPToken,
                                            onUpgrade: { viewModel.upgrade() })

                        if viewModel.showFileAttachmentsSection {
                            FileAttachmentsViewSection(files: viewModel.fileUiModels,
                                                       isFetching: viewModel.files.isFetching,
                                                       fetchError: viewModel.files.error,
                                                       handler: viewModel)
                                .padding(.top, 8)
                        }

                        ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                                 action: viewModel.showItemHistory)

                        ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                                  itemContent: viewModel.itemContent,
                                                  vault: viewModel.vault?.vault,
                                                  onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                            .padding(.top, 24)
                            .id(bottomID)
                    }
                    .padding()
                }
                .animation(.default, value: viewModel.moreInfoSectionExpanded)
                .animation(.default, value: viewModel.password.isEmpty)
                .animation(.default, value: showPenalties)
                .onChange(of: viewModel.moreInfoSectionExpanded) {
                    withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
                }
            }
        }
        .animation(.default, value: viewModel.moreInfoSectionExpanded)
        .animation(.default, value: viewModel.securityIssues)
        .itemDetailSetUp(viewModel)
    }
}

private extension LogInDetailView {
    var usernamePassword2FaSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            if viewModel.email.isEmpty, viewModel.username.isEmpty {
                emptyEmailOrUsernameRow
                PassSectionDivider()
            } else {
                if !viewModel.email.isEmpty {
                    emailRow
                    PassSectionDivider()
                }
                if !viewModel.username.isEmpty {
                    usernameRow
                    PassSectionDivider()
                }
            }

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
                    TOTPRow(uri: viewModel.totpUri,
                            tintColor: iconTintColor,
                            onCopyTotpToken: { viewModel.copyTotpToken($0) })
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.totpTokenState)
    }

    var emptyEmailOrUsernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.envelope, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email or username")
                    .sectionTitleText()

                Text("Empty")
                    .placeholderText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var emailRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.envelope,
                                  color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email address")
                    .sectionTitleText()

                if viewModel.email.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(AttributedString(viewModel.email, attributes: .lineBreakHyphenErasing))
                        .sectionContentText()

                    if viewModel.isAlias {
                        Button { viewModel.showAliasDetail() } label: {
                            Text("View alias")
                                .font(.callout)
                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color)
                                .underline(color: viewModel.itemContent.type.normMajor2Color)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: { viewModel.copyEmail() })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button { viewModel.copyEmail() } label: {
                Text("Copy")
            }

            Button {
                viewModel.showLarge(.text(viewModel.email))
            } label: {
                Text("Show large")
            }
        }
    }

    var usernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()

                if viewModel.username.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.username)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: { viewModel.copyItemUsername() })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button { viewModel.copyItemUsername() } label: {
                Text("Copy")
            }

            Button {
                viewModel.showLarge(.text(viewModel.username))
            } label: {
                Text("Show large")
            }
        }
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            let strength = viewModel.passwordScore?.strength
            let penalties = viewModel.passwordScore?.penalties ?? []
            if let strength {
                PasswordStrengthIcon(strength: strength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key, color: iconTintColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Button(action: { showPenalties.toggle() },
                       label: {
                           Text(strength.sectionTitle)
                               .font(.footnote)
                               .foregroundStyle(strength.sectionTitleColor)
                               .underline(!viewModel.password.isEmpty,
                                          color: strength.sectionTitleColor)
                       })

                if !viewModel.password.isEmpty, showPenalties {
                    PasswordPenaltiesSection(penalties: penalties)
                }

                if viewModel.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    if showPassword {
                        Text(viewModel.password.coloredPassword())
                            .font(.body.monospaced())
                    } else {
                        Text(String(repeating: "•", count: 12))
                            .sectionContentText()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyPassword() }

            Spacer()

            if !viewModel.password.isEmpty {
                CircleButton(icon: showPassword ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: showPassword ? "Hide password" : "Show password",
                             action: { showPassword.toggle() })
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button(action: {
                withAnimation {
                    showPassword.toggle()
                }
            }, label: {
                Text(showPassword ? "Conceal" : "Reveal")
            })

            Button { viewModel.copyPassword() } label: {
                Text("Copy")
            }

            Button { viewModel.showLargePassword() } label: {
                Text("Show large")
            }
        }
    }
}

private extension LogInDetailView {
    var totpNotAllowedRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA limit reached")
                    .sectionTitleText()
                UpgradeButtonLite(foregroundColor: viewModel.itemContentType.normMajor2Color,
                                  action: viewModel.upgrade)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var autofillUrlsSection: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.autofillUrls, id: \.self) { url in
                        Button(action: {
                            viewModel.openUrl(url.url)
                        }, label: {
                            urlRow(url)
                        })
                        .contextMenu {
                            Button(action: {
                                viewModel.openUrl(url.url)
                            }, label: {
                                Text("Open")
                            })

                            Button(action: {
                                viewModel.copyToClipboard(text: url.url,
                                                          message: #localized("Website copied"))
                            }, label: {
                                Text("Copy")
                            })
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.default, value: viewModel.autofillUrls)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    /// The enclosing box exists to group a url with its matching rule, so a url without one
    /// stays a plain row rather than gaining a box nested inside the detail section.
    @ViewBuilder
    func urlRow(_ url: AutofillUrl) -> some View {
        if viewModel.domainMatchingSupported {
            VStack(alignment: .leading, spacing: 4) {
                urlText(url.url)

                if url.mode != .default, let title = url.mode.title {
                    Text(verbatim: title)
                        .foregroundStyle(PassColor.textWeak)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignConstant.sectionPadding / 2)
            .roundedEditableSection()
        } else {
            urlText(url.url)
        }
    }

    func urlText(_ url: String) -> some View {
        Text(verbatim: url)
            .foregroundStyle(viewModel.itemContent.type.normMajor2Color)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
    }
}

private extension LogInDetailView {
    @ViewBuilder
    var securityIssuesView: some View {
        if let issues = viewModel.securityIssues, !issues.isEmpty {
            SecurityIssueView(weaknesses: issues,
                              reusedItems: viewModel.reusedItems,
                              isPerCheckExclusionEnabled: viewModel.isPerCheckExclusionEnabled,
                              onToggleMonitoring: viewModel.toggleMonitoring(weakness:),
                              onShowReusedItemList: viewModel.showItemList,
                              onShowItemDetail: viewModel.showDetail(for:),
                              onRetryFetchReusedItems: viewModel.fetchSimilarPasswordItems)
                .padding(.vertical)
        }
    }
}
