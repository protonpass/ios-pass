//
//
// SecurityWeaknessDetailView.swift
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

struct SecurityWeaknessDetailView: View {
    @StateObject var viewModel: SecurityWeaknessDetailViewModel
    let isSheet: Bool

    var body: some View {
        mainContainer.if(isSheet) { view in
            NavigationStack {
                view
            }
        }
    }
}

private extension SecurityWeaknessDetailView {
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
        .padding(.horizontal, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .showSpinner(viewModel.loading)
        .navigationTitle(viewModel.title)
    }
}

// MARK: - List of Items

private extension SecurityWeaknessDetailView {
    func itemsSections(sections: [SecuritySectionHeaderKey: [ItemContent]]) -> some View {
        ForEach(sections.keys.sorted(by: >), id: \.self) { key in
            Section(content: {
                itemsList(items: sections[key] ?? [])
            }, header: {
                Group {
                    if let iconName = key.iconName {
                        Label(key.title, systemImage: iconName)
                    } else {
                        Text(key.title)
                    }
                }
                .font(.callout)
                .foregroundColor(key.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
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
                .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
    }
}

private extension SecurityWeaknessDetailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: isSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close") {
                viewModel.dismiss(isSheet: isSheet)
            }
        }
    }
}

struct SecuritySectionHeaderKey: Hashable, Comparable, Identifiable {
    let id: String
    let color: Color
    let title: String
    let iconName: String?

    init(id: String = UUID().uuidString,
         color: Color = PassColor.textWeak.toColor,
         title: String,
         iconName: String? = nil) {
        self.color = color
        self.title = title
        self.iconName = iconName
        self.id = id
    }

    static func < (lhs: SecuritySectionHeaderKey, rhs: SecuritySectionHeaderKey) -> Bool {
        lhs.title < rhs.title
    }
}
