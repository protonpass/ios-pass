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

// swiftlint:disable file_length
struct LogInDetailView: View {
    @StateObject private var viewModel: LogInDetailViewModel
    @State private var isShowingPassword = false
    @Namespace private var bottomID

    private var iconTintColor: Color { viewModel.itemContent.type.normColor }

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
                        if viewModel.showSecurityIssues, let issues = viewModel.securityIssues {
                            securityIssuesView(issues: issues)
                                .padding(.vertical)
                        }
                        // TODO: breadcrump view

                        if let share = viewModel.shareContent?.share {
                            BreadcrumbView(share: share, itemPath: viewModel.path)
                            // Custom breadcrumb with any content
//                            BreadcrumbView(items: viewModel.path,
//                                           maxLines: 2) { folder in
//                                Label(folder, systemImage: "folder")
//                                    .foregroundColor(.blue)
//                            } separatorView: {
//                                Image(systemName: "chevron.right")
//                                    .foregroundColor(.secondary)
//                            }
                        }

                        ItemDetailTitleView(itemContent: viewModel.itemContent,
                                            vault: viewModel.vault?.vault)
                            .padding(.vertical, 16)
//                            .padding(.bottom, 40)

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

    var viewAliasCard: some View {
        Group {
            Text("View and edit details for this alias on the separate alias page.")
                .font(.callout)
                .adaptiveForegroundStyle(PassColor.textNorm) +
                Text(verbatim: " ")
                .font(.callout) +
                Text("View")
                .font(.callout)
                .adaptiveForegroundStyle(viewModel.itemContent.type.normMajor2Color)
                .underline(color: viewModel.itemContent.type.normMajor2Color)
        }
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.backgroundMedium)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: viewModel.showAliasDetail)
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
        let showIcon = weakness == .reusedPasswords ? viewModel.reusedItems.isFetched : true
        HStack(spacing: DesignConstant.sectionPadding) {
            if showIcon, let iconName = rowType.detailIcon {
                VStack {
                    Image(systemName: iconName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(rowType.iconColor)
                        .frame(width: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                if let title = weakness.detailTitle {
                    Text(title)
                        .fontWeight(.bold)
                        .foregroundStyle(rowType.iconColor)
                }
                if weakness == .reusedPasswords {
                    reusedList(rowType: rowType)
                        .padding(.vertical, DesignConstant.sectionPadding / 4)
                }
                if let infos = weakness.infos {
                    Text(infos)
                        .font(.callout)
                        .foregroundStyle(rowType.iconColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.reusedItems)
        .roundedDetailSection(backgroundColor: rowType.detailBackground,
                              borderColor: rowType.border)
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
                    .adaptiveForegroundStyle(rowType.iconColor)
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
        }
    }
}

struct BreadcrumbView: View {
    let share: Share
    let itemPath: [FolderUiModel]
    @State private var expanded: Bool = false

    var body: some View {
        Button { expanded.toggle() } label: {
            renderedText
                .animation(.default, value: expanded)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    @ViewBuilder
    func folderElement(folderName: String, isLast: Bool) -> some View {
        HStack(spacing: 4) {
            IconProvider.chevronRight
                .resizable()
                .foregroundStyle(PassColor.textWeak)
                .frame(width: 16, height: 16)
            Label {
                Text(folderName)
                    .fontWeight(isLast ? .bold : .regular)
                    .foregroundStyle(isLast ? PassColor.textNorm : PassColor.textWeak)
            } icon: {
                IconProvider.foldersFilled
                    .resizable()
                    .foregroundStyle(Color(hex: "#E9A944"))
                    .frame(width: 16, height: 16)
            }
        }
    }

    @ViewBuilder
    private var renderedText: some View {
        if let vaultContent = share.vaultContent {
            if !expanded, let lastFolder = itemPath.last {
                HStack(spacing: 4) {
                    Label {
                        Text(vaultContent.name)
                            .lineLimit(1)
                            .foregroundStyle(PassColor.textWeak)
                    } icon: {
                        vaultContent.vaultSmallIcon
                            .resizable()
                            .foregroundStyle(vaultContent.mainColor)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    if itemPath.count > 1 {
                        IconProvider.chevronRight
                            .resizable()
                            .foregroundStyle(PassColor.textWeak)
                            .frame(width: 16, height: 16)
                        Text("...")
                            .foregroundStyle(PassColor.textWeak)
                    }
                    IconProvider.chevronRight
                        .resizable()
                        .foregroundStyle(PassColor.textWeak)
                        .frame(width: 16, height: 16)
                    Label {
                        Text(lastFolder.content.name)
                            .lineLimit(1)
                            .fontWeight(.bold)
                            .foregroundStyle(PassColor.textNorm)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        IconProvider.foldersFilled
                            .resizable()
                            .foregroundStyle(Color(hex: "#E9A944"))
                            .frame(width: 16, height: 16)
                    }
                    Spacer()
                }
            } else {
                AnyLayout(FlowLayout(spacing: 8)) {
                    Label {
                        Text(vaultContent.name)
                            .lineLimit(1)
                            .foregroundStyle(PassColor.textWeak)
                    } icon: {
                        vaultContent.vaultSmallIcon
                            .resizable()
                            .foregroundStyle(vaultContent.mainColor)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    ForEach(itemPath) { folder in
                        let isLast = if let last = itemPath.last, last == folder {
                            true
                        } else {
                            false
                        }
                        folderElement(folderName: folder.content.name, isLast: isLast)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
//                FlowLayout(spacing: 0) {
//                    Group {
//                        Label {
//                            Text(vaultContent.name)
//                                .lineLimit(1)
//                                .foregroundStyle(PassColor.textWeak)
//                        } icon: {
//                            vaultContent.vaultSmallIcon
//                                .resizable()
//                                .foregroundStyle(vaultContent.mainColor)
//                                .scaledToFit()
//                                .frame(width: 16, height: 16)
//                        }
//                        ForEach(itemPath) { folder in
//                            let isLast = if let last = itemPath.last, last == folder {
//                                true
//                            } else {
//                                false
//                            }
//                            folderElement(folderName: folder.content.name, isLast: isLast)
//                        }
//                    }
//                    Spacer()
//                }
//                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var vaultTitle: some View {
        if let vaultContent = share.vaultContent {
            Label { Text(vaultContent.name)
                .lineLimit(1)
                .foregroundStyle(PassColor.textWeak)
            } icon: {
                vaultContent.vaultSmallIcon
                    .resizable()
                    .foregroundStyle(vaultContent.mainColor)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }

            //                vaultContent.vaultSmallIcon
            //                    .resizable()
            //                    .foregroundStyle(vaultContent.mainColor)
            //                    .scaledToFit()
            //                    .frame(width: 16, height: 16)
            //                Text(vaultContent.name)
            //                    .lineLimit(1)
            //                    .foregroundStyle(PassColor.textWeak)
        }
    }

    @ViewBuilder
    private var folderTitles: some View {
        if expanded, itemPath.count > 1 {
        } else if !expanded, itemPath.count > 1 {
        } else {}
    }
}

struct NewFlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width > proposal.width ?? 0 {
                totalHeight += lineHeight
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width
                lineHeight = max(lineHeight, size.height)
            }

            totalWidth = max(totalWidth, lineWidth)
        }

        totalHeight += lineHeight

        return .init(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            if lineX + sizes[index].width > (proposal.width ?? 0) {
                lineY += lineHeight
                lineHeight = 0
                lineX = bounds.minX
            }

            subviews[index].place(at: .init(x: lineX + sizes[index].width / 2,
                                            y: lineY + sizes[index].height / 2),
                                  anchor: .center,
                                  proposal: ProposedViewSize(sizes[index]))

            lineHeight = max(lineHeight, sizes[index].height)
            lineX += sizes[index].width
        }
    }
}

// if let vaultContent = vault?.vaultContent {
//    HStack {
//        VaultLabel(vaultContent: vaultContent)
//        Spacer()
//    }
// }

// import SwiftUI
//
//// MARK: - Layout Protocol Implementation
//
// struct BreadcrumbLayout: Layout {
//    let maxLines: Int
//    let itemSpacing: CGFloat
//    let ellipsis = "..."
//
//    init(maxLines: Int = 2, itemSpacing: CGFloat = 4) {
//        self.maxLines = maxLines
//        self.itemSpacing = itemSpacing
//    }
//
//    func sizeThatFits(proposal: ProposedViewSize,
//                      subviews: Subviews,
//                      cache: inout CacheData) -> CGSize {
//        calculateLayout(in: proposal, subviews: subviews, cache: &cache)
//
//        return CGSize(width: cache.totalWidth,
//                      height: cache.totalHeight)
//    }
//
//    func placeSubviews(in bounds: CGRect,
//                       proposal: ProposedViewSize,
//                       subviews: Subviews,
//                       cache: inout CacheData) {
//        // Place chevrons first (odd indices)
//        for (index, chevronIndex) in cache.chevronPositions.enumerated() {
//            guard chevronIndex < subviews.count else { continue }
//
//            let position = CGPoint(x: bounds.minX + cache.positions[chevronIndex].x,
//                                   y: bounds.minY + cache.positions[chevronIndex].y +
//                                       (cache.lineHeights[cache.lineIndices[chevronIndex]] -
//                                       subviews[chevronIndex]
//                                           .sizeThatFits(.unspecified).height) / 2)
//
//            subviews[chevronIndex].place(at: position,
//                                         anchor: .topLeading,
//                                         proposal: ProposedViewSize(width: cache.chevronSize.width,
//                                                                    height: cache.chevronSize.height))
//        }
//
//        // Place breadcrumb items (even indices)
//        for (index, positionIndex) in cache.itemPositions.enumerated() {
//            guard positionIndex < subviews.count else { continue }
//
//            let position = CGPoint(x: bounds.minX + cache.positions[positionIndex].x,
//                                   y: bounds.minY + cache.positions[positionIndex].y +
//                                       (cache
//                                           .lineHeights[cache.lineIndices[positionIndex]] -
//                                           subviews[positionIndex]
//                                           .sizeThatFits(.unspecified).height) / 2)
//
//            subviews[positionIndex].place(at: position,
//                                          anchor: .topLeading,
//                                          proposal: ProposedViewSize(width: cache.sizes[positionIndex].width,
//                                                                     height: cache.sizes[positionIndex].height))
//        }
//
//        // Place ellipsis if needed
//        if let ellipsisIndex = cache.ellipsisIndex {
//            guard ellipsisIndex < subviews.count else { return }
//
//            let position = CGPoint(x: bounds.minX + cache.positions[ellipsisIndex].x,
//                                   y: bounds.minY + cache.positions[ellipsisIndex].y +
//                                       (cache
//                                           .lineHeights[cache.lineIndices[ellipsisIndex]] -
//                                           subviews[ellipsisIndex]
//                                           .sizeThatFits(.unspecified).height) / 2)
//
//            subviews[ellipsisIndex].place(at: position,
//                                          anchor: .topLeading,
//                                          proposal: ProposedViewSize(width: cache.sizes[ellipsisIndex].width,
//                                                                     height: cache.sizes[ellipsisIndex].height))
//        }
//    }
//
//    // MARK: - Layout Calculation
//
//    private func calculateLayout(in proposal: ProposedViewSize,
//                                 subviews: Subviews,
//                                 cache: inout CacheData) {
//        let availableWidth = proposal.width ?? .infinity
//        let availableHeight = proposal.height ?? .infinity
//
//        // Reset cache
//        cache = CacheData()
//
//        // Early return for empty state
//        guard !subviews.isEmpty else { return }
//
//        // Measure all subviews
//        var idealSizes: [CGSize] = []
//        for subview in subviews {
//            let size = subview.sizeThatFits(.unspecified)
//            idealSizes.append(size)
//        }
//        cache.sizes = idealSizes
//
//        // Find chevrons (they should be at odd indices in a breadcrumb)
//        let chevronIndices = (0..<subviews.count).filter { $0 % 2 == 1 }
//        let itemIndices = (0..<subviews.count).filter { $0 % 2 == 0 }
//
//        // Calculate total width if everything was on one line
//        let totalIdealWidth = idealSizes.reduce(0) { $0 + $1.width } +
//            CGFloat(max(0, subviews.count - 1)) * itemSpacing
//
//        // Check if we need multi-line layout
//        if totalIdealWidth <= availableWidth || maxLines == 1 {
//            // Single line fits
//            layoutSingleLine(subviews: subviews,
//                             indices: Array(0..<subviews.count),
//                             availableWidth: availableWidth,
//                             cache: &cache)
//        } else {
//            // Need multi-line layout
//            layoutMultiLine(subviews: subviews,
//                            itemIndices: itemIndices,
//                            chevronIndices: chevronIndices,
//                            availableWidth: availableWidth,
//                            cache: &cache)
//        }
//
//        // Calculate total height
//        cache.totalHeight = cache.lineHeights.reduce(0) { $0 + $1 } +
//            CGFloat(max(0, cache.lineHeights.count - 1)) * 4 // line spacing
//
//        cache.totalWidth = min(availableWidth, cache.positions.map { $0.x + idealSizes[0].width }.max() ?? 0)
//    }
//
//    private func layoutSingleLine(subviews: Subviews,
//                                  indices: [Int],
//                                  availableWidth: CGFloat,
//                                  cache: inout CacheData) {
//        var currentX: CGFloat = 0
//        let lineIndex = 0
//
//        for (index, subviewIndex) in indices.enumerated() {
//            let size = cache.sizes[subviewIndex]
//
//            cache.positions[subviewIndex] = CGPoint(x: currentX, y: 0)
//            cache.lineIndices[subviewIndex] = lineIndex
//            cache.lineWidths[lineIndex, default: 0] += size.width + (index > 0 ? itemSpacing : 0)
//            cache.lineHeights[lineIndex] = max(cache.lineHeights[lineIndex, default: 0], size.height)
//
//            if subviewIndex % 2 == 1 {
//                cache.chevronPositions.append(subviewIndex)
//            } else {
//                cache.itemPositions.append(subviewIndex)
//            }
//
//            currentX += size.width + itemSpacing
//        }
//    }
//
//    private func layoutMultiLine(subviews: Subviews,
//                                 itemIndices: [Int],
//                                 chevronIndices: [Int],
//                                 availableWidth: CGFloat,
//                                 cache: inout CacheData) {
//        // For breadcrumb, we want to keep first and last items visible
//        guard itemIndices.count >= 2 else {
//            layoutSingleLine(subviews: subviews, indices: Array(0..<subviews.count),
//                             availableWidth: availableWidth, cache: &cache)
//            return
//        }
//
//        let firstItemIndex = itemIndices[0]
//        let lastItemIndex = itemIndices[itemIndices.count - 1]
//
//        // Measure ellipsis size
//        let ellipsisSize = CGSize(width: 20, height: cache.sizes.first?.height ?? 20)
//
//        // Calculate what fits on first line
//        var firstLineIndices: [Int] = []
//        var secondLineIndices: [Int] = []
//
//        // Always put first item on first line
//        firstLineIndices.append(firstItemIndex)
//        if let firstChevronIndex = chevronIndices.first(where: { $0 > firstItemIndex }) {
//            firstLineIndices.append(firstChevronIndex)
//        }
//
//        // Try to fit more items on first line
//        var currentWidth = cache.sizes[firstItemIndex].width
//        var addedToFirstLine = false
//
//        for i in 1..<(itemIndices.count - 1) {
//            let itemIndex = itemIndices[i]
//            let chevronBeforeIndex = chevronIndices.first(where: { $0 < itemIndex }) ?? (itemIndex - 1)
//            let chevronAfterIndex = chevronIndices.first(where: { $0 > itemIndex }) ?? (itemIndex + 1)
//
//            let testWidth = currentWidth +
//                cache.sizes[chevronBeforeIndex].width +
//                cache.sizes[itemIndex].width +
//                cache.sizes[chevronAfterIndex].width +
//                ellipsisSize.width +
//                (itemSpacing * 3)
//
//            if testWidth <= availableWidth {
//                // Add to first line
//                firstLineIndices.append(contentsOf: [chevronBeforeIndex, itemIndex])
//                if i < itemIndices.count - 2 {
//                    firstLineIndices.append(chevronAfterIndex)
//                }
//                currentWidth = testWidth
//                addedToFirstLine = true
//            } else {
//                break
//            }
//        }
//
//        // Add ellipsis to first line if we have more items
//        if addedToFirstLine, itemIndices.count > 2 {
//            // Create a placeholder for ellipsis
//            cache.ellipsisIndex = subviews.count // This would be a virtual index
//            // In real implementation, you'd need to handle ellipsis as a separate view
//        }
//
//        // Put remaining items on second line
//        // Always put last item on second line
//        var secondLineStartIndex = firstLineIndices.last ?? firstItemIndex
//
//        // Skip to after the last item we added to first line
//        if let lastFirstLineItemIndex = firstLineIndices.last(where: { $0 % 2 == 0 }) {
//            let lastItemPosition = itemIndices.firstIndex(of: lastFirstLineItemIndex) ?? 0
//            if lastItemPosition + 1 < itemIndices.count {
//                for i in (lastItemPosition + 1)..<itemIndices.count {
//                    let itemIndex = itemIndices[i]
//                    if i > lastItemPosition + 1 {
//                        if let chevronIndex = chevronIndices
//                            .first(where: { $0 > itemIndices[i - 1] && $0 < itemIndex }) {
//                            secondLineIndices.append(chevronIndex)
//                        }
//                    }
//                    secondLineIndices.append(itemIndex)
//                }
//            }
//        }
//
//        // Layout first line
//        var currentX: CGFloat = 0
//        for (index, subviewIndex) in firstLineIndices.enumerated() {
//            guard subviewIndex < subviews.count else { continue }
//
//            let size = cache.sizes[subviewIndex]
//            cache.positions[subviewIndex] = CGPoint(x: currentX, y: 0)
//            cache.lineIndices[subviewIndex] = 0
//            cache.lineWidths[0, default: 0] += size.width + (index > 0 ? itemSpacing : 0)
//            cache.lineHeights[0] = max(cache.lineHeights[0, default: 0], size.height)
//
//            if subviewIndex % 2 == 1 {
//                cache.chevronPositions.append(subviewIndex)
//            } else {
//                cache.itemPositions.append(subviewIndex)
//            }
//
//            currentX += size.width + itemSpacing
//        }
//
//        // Layout second line
//        currentX = 0
//        let lineHeight = cache.lineHeights[0, default: 0]
//
//        for (index, subviewIndex) in secondLineIndices.enumerated() {
//            guard subviewIndex < subviews.count else { continue }
//
//            let size = cache.sizes[subviewIndex]
//            cache.positions[subviewIndex] = CGPoint(x: currentX, y: lineHeight + 4) // 4 is line spacing
//            cache.lineIndices[subviewIndex] = 1
//            cache.lineWidths[1, default: 0] += size.width + (index > 0 ? itemSpacing : 0)
//            cache.lineHeights[1] = max(cache.lineHeights[1, default: 0], size.height)
//
//            if subviewIndex % 2 == 1 {
//                cache.chevronPositions.append(subviewIndex)
//            } else {
//                cache.itemPositions.append(subviewIndex)
//            }
//
//            currentX += size.width + itemSpacing
//        }
//    }
//
//    // MARK: - Cache
//
//    struct CacheData {
//        var positions: [Int: CGPoint] = [:]
//        var sizes: [CGSize] = []
//        var lineIndices: [Int: Int] = [:]
//        var lineWidths: [Int: CGFloat] = [:]
//        var lineHeights: [Int: CGFloat] = [:]
//        var totalWidth: CGFloat = 0
//        var totalHeight: CGFloat = 0
//        var chevronPositions: [Int] = []
//        var itemPositions: [Int] = []
//        var ellipsisIndex: Int?
//        var chevronSize: CGSize = .init(width: 10, height: 10)
//    }
//
//    func makeCache(subviews: Subviews) -> CacheData {
//        CacheData()
//    }
// }
//
//// MARK: - Breadcrumb View Using Layout
//
// struct BreadcrumbView<Item: Identifiable & Hashable, ItemView: View, SeparatorView: View>: View {
//    let items: [Item]
//    let maxLines: Int
//    let itemSpacing: CGFloat
//    let itemView: (Item) -> ItemView
//    let separatorView: () -> SeparatorView
//
//    init(items: [Item],
//         maxLines: Int = 2,
//         itemSpacing: CGFloat = 4,
//         @ViewBuilder itemView: @escaping (Item) -> ItemView,
//         @ViewBuilder separatorView: @escaping () -> SeparatorView) {
//        self.items = items
//        self.maxLines = maxLines
//        self.itemSpacing = itemSpacing
//        self.itemView = itemView
//        self.separatorView = separatorView
//    }
//
//    var body: some View {
//        if items.isEmpty {
//            Text("No items")
//                .foregroundColor(.secondary)
//        } else if items.count == 1 {
//            itemView(items[0])
//        } else {
//            BreadcrumbLayout(maxLines: maxLines, itemSpacing: itemSpacing) {
//                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
//                    itemView(item)
//
//                    if index < items.count - 1 {
//                        separatorView()
//                    }
//                }
//            }
//        }
//    }
// }
//
//// MARK: - Simplified Breadcrumb View
//
// struct SimpleBreadcrumbView: View {
//    let folders: [String]
//    let maxLines: Int
//
//    init(folders: [String], maxLines: Int = 2) {
//        self.folders = folders
//        self.maxLines = maxLines
//    }
//
//    var body: some View {
//        BreadcrumbView(items: folders,
//                       maxLines: maxLines,
//                       itemSpacing: 4) { folder in
//            Text(folder)
//                .font(.system(size: 14))
//                .lineLimit(1)
//                .truncationMode(.middle)
//        } separatorView: {
//            Image(systemName: "chevron.right")
//                .font(.system(size: 10))
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
// }
//
//// MARK: - Smart Breadcrumb Layout (More Advanced)
//
// struct SmartBreadcrumbLayout: Layout {
//    let maxLines: Int
//    let itemSpacing: CGFloat
//
//    func sizeThatFits(proposal: ProposedViewSize,
//                      subviews: Subviews,
//                      cache: inout Cache) -> CGSize {
//        cache.update(subviews: subviews, proposal: proposal, maxLines: maxLines, itemSpacing: itemSpacing)
//        return cache.totalSize
//    }
//
//    func placeSubviews(in bounds: CGRect,
//                       proposal: ProposedViewSize,
//                       subviews: Subviews,
//                       cache: inout Cache) {
//        for placement in cache.placements {
//            let subview = subviews[placement.index]
//            let x = bounds.minX + placement.position.x
//            let y = bounds.minY + placement.position.y
//
//            subview.place(at: CGPoint(x: x, y: y),
//                          anchor: .topLeading,
//                          proposal: ProposedViewSize(placement.size))
//        }
//    }
//
//    func makeCache(subviews: Subviews) -> Cache {
//        Cache()
//    }
//
//    // MARK: - Cache
//
//    final class Cache {
//        struct Placement {
//            let index: Int
//            let position: CGPoint
//            let size: CGSize
//        }
//
//        var placements: [Placement] = []
//        var totalSize: CGSize = .zero
//
//        func update(subviews: Subviews, proposal: ProposedViewSize, maxLines: Int, itemSpacing: CGFloat) {
//            let availableWidth = proposal.width ?? .infinity
//
//            // Measure all subviews
//            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
//
//            // Calculate ideal single line width
//            let totalWidth = sizes.reduce(0) { $0 + $1.width } +
//                CGFloat(max(0, subviews.count - 1)) * itemSpacing
//
//            if totalWidth <= availableWidth || maxLines == 1 {
//                // Single line layout
//                layoutSingleLine(subviews: subviews, sizes: sizes, itemSpacing: itemSpacing)
//            } else {
//                // Multi-line layout with truncation logic
//                layoutMultiLine(subviews: subviews,
//                                sizes: sizes,
//                                availableWidth: availableWidth,
//                                maxLines: maxLines,
//                                itemSpacing: itemSpacing)
//            }
//        }
//
//        private func layoutSingleLine(subviews: Subviews, sizes: [CGSize], itemSpacing: CGFloat) {
//            placements = []
//            var currentX: CGFloat = 0
//            let maxHeight = sizes.map(\.height).max() ?? 0
//
//            for (index, size) in sizes.enumerated() {
//                placements.append(Placement(index: index,
//                                            position: CGPoint(x: currentX, y: 0),
//                                            size: size))
//                currentX += size.width + itemSpacing
//            }
//
//            totalSize = CGSize(width: currentX - itemSpacing,
//                               height: maxHeight)
//        }
//
//        private func layoutMultiLine(subviews: Subviews,
//                                     sizes: [CGSize],
//                                     availableWidth: CGFloat,
//                                     maxLines: Int,
//                                     itemSpacing: CGFloat) {
//            // Simplified multi-line logic
//            // In production, you'd implement the smart truncation here
//
//            placements = []
//            let itemsPerLine = Int(availableWidth / (sizes.reduce(0) { $0 + $1.width } / CGFloat(sizes.count)))
//
//            var currentX: CGFloat = 0
//            var currentY: CGFloat = 0
//            var currentLineHeight: CGFloat = 0
//            var itemsInCurrentLine = 0
//
//            for (index, size) in sizes.enumerated() {
//                if currentX + size.width > availableWidth ||
//                    (maxLines > 1 && itemsInCurrentLine >= itemsPerLine && !placements.isEmpty) {
//                    // Move to next line
//                    currentX = 0
//                    currentY += currentLineHeight + 4
//                    currentLineHeight = 0
//                    itemsInCurrentLine = 0
//                }
//
//                placements.append(Placement(index: index,
//                                            position: CGPoint(x: currentX, y: currentY),
//                                            size: size))
//
//                currentX += size.width + itemSpacing
//                currentLineHeight = max(currentLineHeight, size.height)
//                itemsInCurrentLine += 1
//            }
//
//            totalSize = CGSize(width: min(availableWidth,
//                                          placements.map { $0.position.x + $0.size.width }.max() ?? 0),
//                               height: currentY + currentLineHeight)
//        }
//    }
// }
//
//// MARK: - Preview
//
// struct BreadcrumbLayout_Previews: PreviewProvider {
//    static let shortPath = ["Home", "Documents", "file.txt"]
//    static let longPath = [
//        "Home",
//        "Users",
//        "john",
//        "Documents",
//        "Projects",
//        "SwiftUI",
//        "Sources",
//        "Views",
//        "file.swift"
//    ]
//
//    static var previews: some View {
//        VStack(spacing: 20) {
//            // Simple breadcrumb
//            SimpleBreadcrumbView(folders: shortPath)
//                .frame(width: 300)
//                .padding()
//                .background(Color.gray.opacity(0.1))
//
//            // Long path with truncation
//            SimpleBreadcrumbView(folders: longPath, maxLines: 2)
//                .frame(width: 300)
//                .padding()
//                .background(Color.gray.opacity(0.1))
//
//            // Custom breadcrumb
//            BreadcrumbView(items: longPath,
//                           maxLines: 2) { folder in
//                Text(folder)
//                    .font(.caption)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(Color.blue.opacity(0.1))
//                    .cornerRadius(4)
//            } separatorView: {
//                Image(systemName: "arrow.right")
//                    .font(.system(size: 8))
//                    .foregroundColor(.blue)
//            }
//            .frame(width: 300)
//            .padding()
//            .background(Color.gray.opacity(0.1))
//        }
//        .padding()
//    }
// }

// swiftlint:enable file_length
