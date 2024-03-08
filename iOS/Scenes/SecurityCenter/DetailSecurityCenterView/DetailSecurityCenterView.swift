//
//
// DetailSecurityCenterView.swift
// Proton Pass - Created on 05/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

struct DetailSecurityCenterView: View {
    @StateObject var viewModel: DetailSecurityCenterViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        mainContainer
            .padding(.horizontal, DesignConstant.sectionPadding)
            .navigationTitle(viewModel.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar { toolbarContent }
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .showSpinner(viewModel.loading)
            .navigationStackEmbeded()
    }
}

private extension DetailSecurityCenterView {
    var mainContainer: some View {
        VStack {
            Text(viewModel.info)
                .foregroundStyle(PassColor.textNorm.toColor)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)

            LazyVStack(spacing: 0) {
                if viewModel.showSections {
                    itemsSections(sections: viewModel.sectionedData)
                } else {
                    itemsList(items: viewModel.sectionedData.flatMap(\.value))
                }
                Spacer()
            }
        }
    }
}

// MARK: - List of Items

private extension DetailSecurityCenterView {
    func itemsSections(sections: [SecuritySectionHeaderKey: [ItemContent]]) -> some View {
        ForEach(sections.keys.sorted(), id: \.self) { key in
            Section(content: {
                itemsList(items: sections[key] ?? [])
            }, header: {
                Group {
                    if let iconName = key.iconName {
                        Label(key.title, systemImage: iconName)
                    } else {
                        Text(key.title)
                    }
                }.font(.callout)
                    .foregroundColor(key.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
    }

    func itemsList(items: [ItemContent]) -> some View {
        ForEach(items) { item in
            itemRow(for: item)
        }
    }

    func itemRow(for item: ItemContent) -> some View {
        Button {
            viewModel.showDetail(item: item)
        } label: {
            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                           title: item.title,
                           description: item.toItemUiModel.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private extension DetailSecurityCenterView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1) {
                dismiss()
            }
        }
    }
}

struct SecuritySectionHeaderKey: Hashable, Comparable {
    let color: Color
    let title: String
    let iconName: String?

    static func < (lhs: SecuritySectionHeaderKey, rhs: SecuritySectionHeaderKey) -> Bool {
        lhs.title < rhs.title
    }
}
