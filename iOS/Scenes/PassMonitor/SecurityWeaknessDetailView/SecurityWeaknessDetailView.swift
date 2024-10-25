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

import Core
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct SecurityWeaknessDetailView: View {
    @StateObject var viewModel: SecurityWeaknessDetailViewModel
    @State private var collapsedSections = Set<SecuritySectionHeaderKey>()

    @AppStorage(Constants.QA.useSwiftUIList, store: kSharedUserDefaults)
    private var useSwiftUIList = false

    let isSheet: Bool

    var body: some View {
        mainContainer
            .navigationStackEmbeded()
    }
}

private extension SecurityWeaknessDetailView {
    var mainContainer: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .fetching:
                ProgressView()
                    .controlSize(.large)

            case let .fetched(data):
                if let subtitleInfo = viewModel.type.subtitleInfo {
                    Text(subtitleInfo)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
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
                    if useSwiftUIList {
                        lazyVStack(for: data)
                    } else {
                        tableView(for: data)
                    }
                }

            case let .error(error):
                Text(error.localizedDescription)
                    .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
        .animation(.default, value: collapsedSections)
        .toolbar { toolbarContent }
        // `TableView` wouldn't work when embeded in a scroll view
        .if(viewModel.state.fetchedObject?.isEmpty == false && useSwiftUIList) { view in
            view.scrollViewEmbeded(maxWidth: .infinity)
        }
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.type.title)
    }
}

// MARK: - List of Items

private extension SecurityWeaknessDetailView {
    func lazyVStack(for data: SecuritySectionedData) -> some View {
        LazyVStack(spacing: 0) {
            if viewModel.type.isSectionned {
                itemsSections(sections: data)
            } else {
                forEach(data.flatMap(\.value))
            }
        }
        .padding(.horizontal)
    }

    func itemsSections(sections: SecuritySectionedData) -> some View {
        ForEach(sections.sortedMostWeakness) { key in
            Section(content: {
                if !collapsedSections.contains(key), let items = sections[key] {
                    forEach(items)
                }
            }, header: {
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
            })
        }
    }

    func forEach(_ items: [ItemUiModel]) -> some View {
        ForEach(items) { item in
            Row(item: item) {
                viewModel.showDetail(item: item)
            }
        }
    }
}

private struct Row: View {
    let item: ItemUiModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                           title: item.title,
                           description: item.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private extension SecurityWeaknessDetailView {
    @ViewBuilder
    func tableView(for data: SecuritySectionedData) -> some View {
        let sections: [TableView<ItemUiModel, Row, Text>.Section] = data.map { key, value in
            .init(type: key.title, title: key.title, items: value)
        }
        TableView(sections: sections,
                  configuration: .init(),
                  id: sections.hashValue,
                  itemView: { item in
                      Row(item: item) {
                          viewModel.showDetail(item: item)
                      }
                  },
                  headerView: { _ in nil })
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
    var isSectionned: Bool {
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

private extension SecuritySectionedData {
    var sortedMostWeakness: [SecuritySectionHeaderKey] {
        keys.sorted {
            (self[$0]?.count ?? 0) > (self[$1]?.count ?? 0)
        }
    }
}
