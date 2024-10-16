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
    @State private var collapsedSections = Set<SecuritySectionHeaderKey>()
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
            switch viewModel.state {
            case .fetching:
                ProgressView()

            case let .fetched(data):
                if let subtitleInfo = viewModel.type.subtitleInfo {
                    Text(subtitleInfo)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                }

                if data.isEmpty {
                    Spacer()
                    Image(uiImage: PassIcon.securityEmptyState)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 195)
                    Text(viewModel.nothingWrongMessage)
                        .foregroundStyle(PassColor.textHint.toColor)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Spacer()
                } else {
                    LazyVStack(spacing: 0) {
                        if viewModel.type.hasSections {
                            itemsSections(sections: data)
                        } else {
                            itemsList(items: data.flatMap(\.value))
                        }
                        Spacer()
                    }
                }

            case let .error(error):
                Text(error.localizedDescription)
                    .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
        .animation(.default, value: collapsedSections)
        .toolbar { toolbarContent }
        .if(viewModel.state.fetchedObject?.isEmpty == false) { view in
            view.scrollViewEmbeded(maxWidth: .infinity)
        }
        .background(PassColor.backgroundNorm.toColor)
        .navigationTitle(viewModel.type.title)
    }
}

// MARK: - List of Items

private extension SecurityWeaknessDetailView {
    func itemsSections(sections: [SecuritySectionHeaderKey: [ItemContent]]) -> some View {
        ForEach(sections.sortedMostWeakness) { key in
            Section(content: {
                if !collapsedSections.contains(key), let items = sections[key] {
                    itemsList(items: items)
                }
            }, header: {
                header(for: key)
            })
        }
    }

    func header(for key: SecuritySectionHeaderKey) -> some View {
        Label(title: { Text(key.title) },
              icon: {
                  if viewModel.type.collapsible {
                      Image(systemName: collapsedSections.contains(key) ? "chevron.up" : "chevron.down")
                          .resizable()
                          .scaledToFit()
                          .frame(width: 12)
                  }
              })
              .foregroundStyle(PassColor.textWeak.toColor)
              .frame(maxWidth: .infinity, alignment: .leading)
              .if(viewModel.type.collapsible) { view in
                  view
                      .padding(.top, DesignConstant.sectionPadding)
                      .buttonEmbeded {
                          if collapsedSections.contains(key) {
                              collapsedSections.remove(key)
                          } else {
                              collapsedSections.insert(key)
                          }
                      }
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
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: isSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close") {
                viewModel.dismiss(isSheet: isSheet)
            }
        }
    }
}

struct SecuritySectionHeaderKey: Hashable, Comparable, Identifiable {
    let id = UUID().uuidString
    let title: String

    static func < (lhs: SecuritySectionHeaderKey, rhs: SecuritySectionHeaderKey) -> Bool {
        lhs.title < rhs.title
    }
}

private extension SecurityWeakness {
    var hasSections: Bool {
        switch self {
        case .excludedItems, .missing2FA, .weakPasswords:
            false
        default:
            true
        }
    }

    var collapsible: Bool {
        if case .reusedPasswords = self {
            return true
        }
        return false
    }
}

private extension [SecuritySectionHeaderKey: [ItemContent]] {
    var sortedMostWeakness: [SecuritySectionHeaderKey] {
        self.keys.sorted {
            (self[$0]?.count ?? 0) > (self[$1]?.count ?? 0)
        }
    }
}
