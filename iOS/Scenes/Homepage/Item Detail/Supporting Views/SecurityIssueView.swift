//
// SecurityIssueView.swift
// Proton Pass - Created on 16/06/2026.
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

struct SecurityIssueView: View {
    let weaknesses: [ItemWeaknessDisplay]
    @ObservedObject var viewModel: LogInDetailViewModel
    @State private var expanded: Bool = false

    var body: some View {
        mainContent
    }

    var mainContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow

            weaknessContent
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: expanded)
    }

    @ViewBuilder
    var headerRow: some View {
        if multipleWeakness {
            Button { expanded.toggle() } label: {
                HStack {
                    Image(uiImage: expanded ? IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .foregroundStyle(PassColor.textNorm)
                    mainHeader
                }
            }
            .buttonStyle(.plain)
        } else {
            mainHeader
        }
    }

    @ViewBuilder
    var weaknessContent: some View {
        if multipleWeakness, !expanded {
            HStack {
                Color.clear
                    .frame(width: 16)
                contentNonExpended
                    .font(.subheadline)
                    .foregroundStyle(PassColor.textNorm)
                    .layoutPriority(1)
            }
        } else {
            ForEach(weaknesses) { weakness in
                securityWeaknessRow(weakness: weakness)
                if weakness != weaknesses.last {
                    Divider()
                }
            }
        }
    }

    var multipleWeakness: Bool {
        weaknesses.count > 1
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
        weaknesses.enumerated().reduce(Text(verbatim: "")) { result, element in
            let (index, issue) = element

            let separator = index > 0 ? Text(verbatim: " · ")
                .foregroundStyle(PassColor.textNorm) : Text(verbatim: "")

            return result
                + separator
                + Text(issue.shortTitle)
                .foregroundStyle(issue.color)
        }
    }

    func securityWeaknessRow(weakness: ItemWeaknessDisplay) -> some View {
        HStack(alignment: .center, spacing: 8) {
            rowIcon(weakness: weakness)
            VStack {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                        Text(weakness.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(weakness.color)
                        if case .weakness(.reusedPassword, _) = weakness {
                            reusedText()
                        } else if let infos = weakness.infos {
                            Text(infos)
                                .font(.subheadline)
                                .foregroundStyle(PassColor.textNorm)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack {
                        CapsuleTextButton(title: weakness
                            .isExcluded ? #localized("Restore alert") : #localized("Ignore"),
                            titleColor: PassColor.interactionNormMajor2,
                            font: .subheadline,
                            backgroundColor: PassColor.loginInteractionNormMinor2,
                            maxWidth: nil,
                            horizontalPadding: buttonPadding,
                            action: {
                                viewModel.toggleMonitoring(weakness: weakness)
                            })
                        Spacer()
                    }
                }

                if case .weakness(.reusedPassword, _) = weakness {
                    reusedList()
                }
            }
        }
        .animation(.default, value: viewModel.reusedItems)
    }

    @ViewBuilder
    func rowIcon(weakness: ItemWeaknessDisplay) -> some View {
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
                .font(.subheadline)
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

    private var buttonPadding: CGFloat {
        if #available(iOS 26.0, *) {
            0
        } else {
            DesignConstant.sectionPadding
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
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(PassColor.textNorm)
                        }
                        .padding(6)
                        .frame(maxWidth: 165, alignment: .leading)
                        .background(PassColor.backgroundMedium)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}
