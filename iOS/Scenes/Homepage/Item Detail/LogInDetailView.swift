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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
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
            NavigationStack {
                realBody
            }
        } else {
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
                        if viewModel.showSecurityIssues, let issues = viewModel.securityIssues {
                            securityIssuesView(issues: issues)
                                .padding(.vertical)
                        }

                        ItemDetailTitleView(itemContent: viewModel.itemContent,
                                            vault: viewModel.vault?.vault,
                                            shouldShowVault: viewModel.shouldShowVault)
                            .padding(.bottom, 40)

                        if !viewModel.passkeys.isEmpty {
                            ForEach(viewModel.passkeys, id: \.keyID) { passkey in
                                PasskeyDetailRow(passkey: passkey,
                                                 onTap: { viewModel.viewPasskey(passkey) })
                                    .padding(.bottom, 8)
                            }
                        }

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
                                                 action: { viewModel.showItemHistory() })

                        ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                                  itemContent: viewModel.itemContent,
                                                  onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
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
                    Text(viewModel.email)
                        .sectionContentText()

                    if viewModel.isAlias {
                        Button { viewModel.showAliasDetail() } label: {
                            Text("View alias")
                                .font(.callout)
                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
                                .underline(color: viewModel.itemContent.type.normMajor2Color.toColor)
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
            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.user,
                                  color: iconTintColor)

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
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key, color: iconTintColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.passwordStrength.sectionTitle(reuseCount: viewModel.reusedItems?.count))
                    .font(.footnote)
                    .foregroundStyle(viewModel.passwordStrength.sectionTitleColor)

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
            .contentShape(.rect)
            .onTapGesture { viewModel.copyPassword() }

            Spacer()

            if !viewModel.password.isEmpty {
                CircleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: isShowingPassword ? "Hide password" : "Show password",
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
}

private extension LogInDetailView {
    var totpNotAllowedRow: some View {
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

    var urlsSection: some View {
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
                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
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

    var viewAliasCard: some View {
        Group {
            Text("View and edit details for this alias on the separate alias page.")
                .font(.callout)
                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                Text(verbatim: " ")
                .font(.callout) +
                Text("View")
                .font(.callout)
                .adaptiveForegroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
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

private extension LogInDetailView {
    func securityIssuesView(issues: [SecurityWeakness]) -> some View {
        VStack {
            ForEach(issues, id: \.self) {
                securityWeaknessRow(weakness: $0)
            }
        }
    }

    @ViewBuilder
    func securityWeaknessRow(weakness: SecurityWeakness) -> some View {
        let rowType = weakness.secureRowType
        HStack(spacing: DesignConstant.sectionPadding) {
            if let iconName = rowType.detailIcon {
                VStack {
                    Image(systemName: iconName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(rowType.iconColor.toColor)
                        .frame(width: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                if let title = weakness.detailTitle {
                    Text(title)
                        .fontWeight(.bold)
                        .foregroundStyle(rowType.iconColor.toColor)
                }
                if weakness == .reusedPasswords {
                    reusedList(rowType: rowType)
                        .padding(.vertical, DesignConstant.sectionPadding / 4)
                }
                if let infos = weakness.infos {
                    Text(infos)
                        .font(.callout)
                        .foregroundStyle(rowType.iconColor.toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: rowType.detailBackground,
                              borderColor: rowType.border)
    }

    @ViewBuilder
    func reusedList(rowType: SecureRowType) -> some View {
        if let reusedItems = viewModel.reusedItems, !reusedItems.isEmpty {
            let reuseText: () -> Text = {
                Text("\(reusedItems.count) other logins use this password")
                    .fontWeight(.bold)
                    .adaptiveForegroundStyle(rowType.iconColor.toColor)
            }
            if reusedItems.count > 5 {
                reuseText()
                HStack {
                    CapsuleTextButton(title: #localized("See all"),
                                      titleColor: rowType.iconColor,
                                      backgroundColor: rowType.iconColor.withAlphaComponent(0.2),
                                      action: { viewModel.showItemList() })
                        .fixedSize(horizontal: true, vertical: true)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading) {
                    reuseText()
                    ReusedItemsPassListView(reusedPasswordItems: reusedItems,
                                            action: { viewModel.showDetail(for: $0) })
                }
            }
        }
    }
}

struct ReusedItemsPassListView: View {
    let reusedPasswordItems: [ItemContent]
    let action: (ItemContent) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(reusedPasswordItems) { item in
                    Button {
                        action(item)
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            ItemSquircleThumbnail(data: item.thumbnailData(),
                                                  size: .small,
                                                  alternativeBackground: true)
                            Text(item.title)
                                .lineLimit(1)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding(.trailing, 8)
                        }
                        .padding(8)
                        .frame(maxWidth: 165, alignment: .leading)
                        .background(item.type.normMinor1Color.toColor)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
}
