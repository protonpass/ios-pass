//
// SecurityIssueView.swift
// Proton Pass - Created on 24/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import SwiftUI

public struct SecurityIssueView: View, Equatable {
    let weaknesses: [ItemWeaknessDisplay]
    let reusedItems: FetchableObject<[ItemContent]>
    let isPerCheckExclusionEnabled: Bool
    let onToggleMonitoring: (ItemWeaknessDisplay) -> Void
    let onShowReusedItemList: () -> Void
    let onShowItemDetail: (ItemContent) -> Void
    let onRetryFetchReusedItems: () -> Void
    @State private var expanded = false

    public init(weaknesses: [ItemWeaknessDisplay],
                reusedItems: FetchableObject<[ItemContent]>,
                isPerCheckExclusionEnabled: Bool,
                onToggleMonitoring: @escaping (ItemWeaknessDisplay) -> Void,
                onShowReusedItemList: @escaping () -> Void,
                onShowItemDetail: @escaping (ItemContent) -> Void,
                onRetryFetchReusedItems: @escaping () -> Void) {
        self.weaknesses = weaknesses
        self.reusedItems = reusedItems
        self.isPerCheckExclusionEnabled = isPerCheckExclusionEnabled
        self.onToggleMonitoring = onToggleMonitoring
        self.onShowReusedItemList = onShowReusedItemList
        self.onShowItemDetail = onShowItemDetail
        self.onRetryFetchReusedItems = onRetryFetchReusedItems
    }

    public var body: some View {
        let isExpandable = weaknesses.count > 1
        VStack(alignment: .leading, spacing: 10) {
            SecurityIssueHeader(isExpandable: isExpandable, expanded: $expanded)

            if isExpandable, !expanded {
                SecurityIssueSummary(weaknesses: weaknesses)
                    .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(weaknesses) { weakness in
                        SecurityWeaknessRow(weakness: weakness,
                                            reusedItems: reusedItems,
                                            isToggleable: isPerCheckExclusionEnabled || weakness == .fullyExcluded,
                                            onToggleMonitoring: { onToggleMonitoring(weakness) },
                                            onShowReusedItemList: onShowReusedItemList,
                                            onShowItemDetail: onShowItemDetail,
                                            onRetryFetchReusedItems: onRetryFetchReusedItems)
                        if weakness != weaknesses.last {
                            Divider()
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(DesignConstant.sectionPadding)
        .animation(.default, value: reusedItems)
        .roundedDetailSection()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.weaknesses == rhs.weaknesses &&
            lhs.reusedItems == rhs.reusedItems &&
            lhs.isPerCheckExclusionEnabled == rhs.isPerCheckExclusionEnabled
    }
}

private struct SecurityIssueHeader: View {
    let isExpandable: Bool
    @Binding var expanded: Bool

    var body: some View {
        if isExpandable {
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(uiImage: IconProvider.chevronRightFilled)
                        .resizable().scaledToFit().frame(width: 16)
                        .foregroundStyle(PassColor.textNorm)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .accessibilityHidden(true)
                    title
                }
            }
            .buttonStyle(.plain)
        } else {
            title
        }
    }

    private var title: some View {
        HStack {
            Text("Pass Monitor", bundle: .module)
                .fontWeight(.semibold)
                .foregroundStyle(PassColor.textNorm)
            Spacer()
            PassIcon.shieldWarning
                .accessibilityHidden(true)
        }
    }
}

private struct SecurityIssueSummary: View {
    let weaknesses: [ItemWeaknessDisplay]

    var body: some View {
        weaknesses.enumerated().reduce(Text(verbatim: "")) { result, element in
            let (index, issue) = element

            let separator = index > 0 ? Text(verbatim: " · ")
                .foregroundStyle(PassColor.textNorm) : Text(verbatim: "")

            return result
                + separator
                + Text(verbatim: issue.shortTitle)
                .foregroundStyle(issue.color)
        }
        .font(.subheadline)
        .foregroundStyle(PassColor.textNorm)
        // Aligns with the header title, past the 16pt chevron and its 8pt spacing
        .padding(.leading, 24)
    }
}

private struct SecurityWeaknessRow: View {
    let weakness: ItemWeaknessDisplay
    let reusedItems: FetchableObject<[ItemContent]>
    let isToggleable: Bool
    let onToggleMonitoring: () -> Void
    let onShowReusedItemList: () -> Void
    let onShowItemDetail: (ItemContent) -> Void
    let onRetryFetchReusedItems: () -> Void

    private var isReusedPassword: Bool {
        if case .weakness(.reusedPassword, _) = weakness {
            true
        } else {
            false
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            weakness.icon
                .resizable().scaledToFit()
                .frame(width: 16)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                        Text(verbatim: weakness.title)
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundStyle(weakness.color)
                        if isReusedPassword {
                            if case let .fetched(items) = reusedItems {
                                Text("\(items.count) other logins use this password", bundle: .module)
                                    .font(.subheadline)
                                    .foregroundStyle(PassColor.textNorm)
                            }
                        } else if let infos = weakness.infos {
                            Text(verbatim: infos).font(.subheadline)
                                .foregroundStyle(PassColor.textNorm)
                        }
                    }

                    Spacer()
                    if isToggleable {
                        CapsuleTextButton(title: weakness.isExcluded
                            ? #localized("Restore alert", bundle: .module) : #localized("Ignore", bundle: .module),
                            titleColor: PassColor.interactionNormMajor2,
                            font: .subheadline,
                            backgroundColor: PassColor.loginInteractionNormMinor2,
                            maxWidth: nil,
                            horizontalPadding: buttonPadding,
                            action: onToggleMonitoring)
                    }
                }

                if isReusedPassword {
                    ReusedPasswordSection(reusedItems: reusedItems,
                                          onShowReusedItemList: onShowReusedItemList,
                                          onShowItemDetail: onShowItemDetail,
                                          onRetry: onRetryFetchReusedItems)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var buttonPadding: CGFloat {
        if #available(iOS 26.0, *) {
            0
        } else {
            DesignConstant.sectionPadding
        }
    }
}

private struct ReusedPasswordSection: View {
    let reusedItems: FetchableObject<[ItemContent]>
    let onShowReusedItemList: () -> Void
    let onShowItemDetail: (ItemContent) -> Void
    let onRetry: () -> Void

    var body: some View {
        switch reusedItems {
        case .fetching:
            ProgressView()
                .tint(PassColor.textNorm)

        case let .fetched(reusedItems):
            if reusedItems.count > 5 {
                CapsuleTextButton(title: #localized("See all", bundle: .module),
                                  titleColor: PassColor.loginInteractionNormMajor2,
                                  backgroundColor: PassColor.loginInteractionNormMinor2,
                                  action: onShowReusedItemList)
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ReusedItemsPassListView(reusedPasswordItems: reusedItems,
                                        action: onShowItemDetail)
            }

        case let .error(error):
            RetryableErrorView(mode: .defaultHorizontal,
                               tintColor: PassColor.loginInteractionNormMajor2,
                               error: error,
                               onRetry: onRetry)
        }
    }
}

private struct ReusedItemsPassListView: View {
    let reusedPasswordItems: [ItemContent]
    let action: (ItemContent) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(reusedPasswordItems) { item in
                    Button {
                        action(item)
                    } label: {
                        HStack(alignment: .center, spacing: 6) {
                            ItemSquircleThumbnail(data: item.thumbnailData(),
                                                  size: .small,
                                                  alternativeBackground: true)
                            Text(verbatim: item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(PassColor.textNorm)
                        }
                        .padding(6)
                        .frame(maxWidth: 165, alignment: .leading)
                        .background(PassColor.backgroundMedium)
                        .clipShape(.rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}
