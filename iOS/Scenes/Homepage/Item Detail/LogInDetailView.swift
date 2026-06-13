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
    @State private var isShowingPassword = false
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
                        securityIssuesView()
                            .padding(.vertical)

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
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key, color: iconTintColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.passwordStrength
                    .sectionTitle(reuseCount: viewModel.reusedItems.fetchedObject?.count))
                    .font(.footnote)
                    .foregroundStyle(viewModel.passwordStrength.sectionTitleColor)

                if viewModel.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    if isShowingPassword {
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
                CircleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: isShowingPassword ? "Hide password" : "Show password",
                             action: { isShowingPassword.toggle() })
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
                UpgradeButtonLite(foregroundColor: viewModel.itemContentType.normMajor2Color,
                                  action: viewModel.upgrade)
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
                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color)
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
}

private extension LogInDetailView {
    @ViewBuilder
    func securityIssuesView() -> some View {
        if let issues = viewModel.securityIssues, !issues.isEmpty {
//            SecurityIssueView(weaknesses: issues,
//                              ignoreExcluded: !viewModel.showExcludedWeaknesses,
//                              viewModel: viewModel)
            SecurityIssueView(weaknesses: issues,
//                              showExcludedWeaknesses: viewModel.showExcludedWeaknesses,
                              viewModel: viewModel)
        }
    }

    @ViewBuilder
    func reusedList(rowType: SecureRowType) -> some View {
        switch viewModel.reusedItems {
        case .fetching:
            ProgressView()
                .tint(rowType.iconColor)

        case let .fetched(reusedItems):
            let reuseText: () -> Text = {
                Text("\(reusedItems.count) other logins use this password")
                    .fontWeight(.bold)
                    .foregroundStyle(rowType.iconColor)
            }
            if reusedItems.count > 5 {
                reuseText()
                HStack {
                    CapsuleTextButton(title: #localized("See all"),
                                      titleColor: rowType.iconColor,
                                      backgroundColor: rowType.iconColor.opacity(0.2),
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

        case let .error(error):
            RetryableErrorView(mode: .defaultHorizontal,
                               tintColor: PassColor.loginInteractionNormMajor2,
                               error: error,
                               onRetry: viewModel.fetchSimilarPasswordItems)
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
                                .foregroundStyle(PassColor.textNorm)
                                .padding(.trailing, 8)
                        }
                        .padding(8)
                        .frame(maxWidth: 165, alignment: .leading)
                        .background(item.type.normMinor1Color)
                        .cornerRadius(16)
                    }
                }
            }
        }.scrollBounceBehavior(.basedOnSize)
    }
}

struct SecurityIssueView: View {
    let weaknesses: [SecurityWeakness]
//    let ignoreExcluded: Bool
//    let showExcludedWeaknesses: Bool
    @ObservedObject var viewModel: LogInDetailViewModel
    @State private var expanded: Bool = false

    var body: some View {
//        if !ignoreExcluded || !weaknesses.filter(\.isExcluded).isEmpty {
        mainContent
            .animation(.default, value: expanded)
//        }
    }

    var mainContent: some View {
        VStack(spacing: 10) {
            headerRow

            weaknessContent
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    @ViewBuilder
    var headerRow: some View {
        if multipleWeakness {
            Button { expanded.toggle() } label: {
                HStack {
                    Image(uiImage: expanded ? IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
                        .foregroundStyle(PassColor.textNorm)
                    mainHeader
                }
            }
        } else {
            mainHeader
        }
    }

    @ViewBuilder
    var weaknessContent: some View {
        if multipleWeakness, !expanded {
            contentNonExpended
                .foregroundStyle(PassColor.textNorm)
        } else {
            ForEach(weaknesses) { weakness in
//                if !ignoreExcluded || weakness.isExcluded {
                securityWeaknessRow(weakness: weakness)
                if weakness != weaknesses.last {
                    Divider()
                }
//                }
            }
        }
    }

    var multipleWeakness: Bool {
        weaknesses.count /* (where: { !ignoreExcluded || $0.isExcluded }) */ > 1
    }

    var mainHeader: some View {
        HStack {
            Text("Pass Monitor")
                .fontWeight(.semibold)
                .foregroundStyle(PassColor.textNorm)
            Spacer()
            PassIcon.shieldWarning
        }
    }

    var contentNonExpended: some View {
        weaknesses.enumerated().reduce(Text("")) { result, element in
            let (index, issue) = element

            let separator = index > 0 ? Text(verbatim: " · ")
                .foregroundStyle(PassColor.textNorm) : Text(verbatim: "")

            return result
                + separator
                + Text(issue.title)
                .foregroundStyle(issue.color)
        }
    }

//    var contentNonExpended: some View {
//        var result: Text
//
//        for weakness in weaknesses {
//            guard let title = weakness.titleTest else {
//                continue
//            }
//            let text = Text(title)
//                .foregroundStyle(.red)
//            result += text
//        }
//
//        let text = weaknesses.compactMap { weakness in
//            guard let title = weakness.titleTest else {
//                return nil
//            }
//            return Text(title)
//                .foregroundStyle(.red)
//        }.joined(separator: Text(" · "))
//
//        return result
//    }

    func securityWeaknessRow(weakness: SecurityWeakness) -> some View {
        HStack(alignment: .center, spacing: 8) {
            rowIcon(weakness: weakness)
            VStack {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                        if let title = weakness.detailTitle {
                            Text(title)
                                .fontWeight(.bold)
                                .foregroundStyle(weakness.color)
                        }
                        if case .reusedPasswords = weakness {
                            reusedText()
                        } else if let infos = weakness.infos {
                            Text(infos)
                                .font(.callout)
                                .foregroundStyle(PassColor.textNorm)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack {
                        CapsuleTextButton(title: #localized("%@",
                                                            weakness.isExcluded ? "Restore alert" : "Ignore"),
                                          titleColor: PassColor.loginInteractionNormMajor2,
                                          backgroundColor: PassColor.loginInteractionNormMinor2,
                                          maxWidth: nil,
                                          action: {
                                              viewModel.toggleMonitoring(weakness: weakness)
                                          })
                        Spacer()
                    }
                }

                if case .reusedPasswords = weakness {
                    reusedList()
                }
            }
        }
        .animation(.default, value: viewModel.reusedItems)
    }

    @ViewBuilder
    func rowIcon(weakness: SecurityWeakness) -> some View {
        if let icon = weakness.icon {
            VStack {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
                    .padding(.top, 2)
                Spacer()
            }
        }
    }

    @ViewBuilder
    func reusedText() -> some View {
        switch viewModel.reusedItems {
        case .fetching:
            ProgressView()
                .tint(PassColor.textNorm)

        case let .fetched(reusedItems):
            Text("\(reusedItems.count) other logins use this password")
                .foregroundStyle(PassColor.textNorm)

        case let .error(error):
            RetryableErrorView(mode: .defaultHorizontal,
                               tintColor: PassColor.loginInteractionNormMajor2,
                               error: error,
                               onRetry: viewModel.fetchSimilarPasswordItems)
        }
    }

    @ViewBuilder
    func reusedList() -> some View {
        switch viewModel.reusedItems {
        case .fetching:
            ProgressView()
                .tint(PassColor.textNorm)

        case let .fetched(reusedItems):
            if reusedItems.count > 5 {
                HStack {
                    CapsuleTextButton(title: #localized("See all"),
                                      titleColor: PassColor.loginInteractionNormMajor2,
                                      backgroundColor: PassColor.loginInteractionNormMinor2,
                                      action: { viewModel.showItemList() })
                        .fixedSize(horizontal: true, vertical: true)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ReusedItemsPassListView(reusedPasswordItems: reusedItems,
                                        action: { viewModel.showDetail(for: $0) })
            }

        case let .error(error):
            RetryableErrorView(mode: .defaultHorizontal,
                               tintColor: PassColor.loginInteractionNormMajor2,
                               error: error,
                               onRetry: viewModel.fetchSimilarPasswordItems)
        }
    }
}

// public struct ItemPathBreadcrumbView: View {
//    let vaultContent: VaultContent
//    let path: [FolderUiModel]
//    @State private var expanded: Bool = false
//
//    public init(vaultContent: VaultContent, path: [FolderUiModel]) {
//        self.vaultContent = vaultContent
//        self.path = path
//        expanded = expanded
//    }
//
//    public var body: some View {
//        if path.isEmpty {
//            EmptyView()
//        } else {
//            Button { expanded.toggle() } label: {
//                breadcrumb
//            }
//            .padding(DesignConstant.sectionPadding)
//            .roundedDetailSection()
//            .animation(.default, value: expanded)
//        }
//    }
// }

extension SecurityWeakness {
    var titleTest: String? {
        switch self {
        case .weakPasswords:
            "Weak passwords"

        case .reusedPasswords:
            "Reused passwords"

        case .missing2FA:
            "Missing 2FA"

        default:
            nil
        }
    }

    var icon: Image? {
        switch self {
        case .missing2FA:
            PassIcon.shieldLockPurple

        case .reusedPasswords:
            PassIcon.reusedKey

        case .weakPasswords:
            PassIcon.shieldBad

        default:
            nil
        }
    }

    var longTitle: String? {
        switch self {
        case .missing2FA:
            "Set up 2FA for more security"

        default:
            titleTest
        }
    }

    var description: String? {
        switch self {
        case .weakPasswords:
            "This account is vulnerable, visit the service and change your password."

        case .reusedPasswords:
            "This service offers 2FA. Enable it for added account security. "

        default:
            nil
        }
    }

    var color: Color {
        switch self {
        case .weakPasswords:
            PassColor.signalDanger

        case .reusedPasswords:
            PassColor.signalWarning

        default:
            PassColor.textNorm
        }
    }
}

//    static let reusedKey = Image(.reusedKey)
//    static let shieldBad = Image(.shieldBad)
//    static let shieldExclamationFilled = Image(.shieldExclamationFilled)
//    static let shieldLock = Image(.shieldLock)
//    static let shieldWarning = Image(.shieldWarning)

// public enum SecurityWeakness: Equatable, Sendable, Hashable, Identifiable {
//    case weakPasswords
//    case reusedPasswords
//    case breaches
//    case missing2FA
//    case excluded(ExclusionType)
