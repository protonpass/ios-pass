//
//
// SecureLinkListView.swift
// Proton Pass - Created on 11/06/2024.
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

struct SecureLinkListView: View {
    @StateObject private var viewModel = SecureLinkListViewModel()
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation

    private let columns = [GridItem](repeating: .init(.flexible()),
                                     count: UIDevice.current.isIpad ? 3 : 2)

    private enum GeoMatchIds {
        case expire(String)
        case view(String)
        case internalContainer(String)
        case externalContainer(String)
        case stack(String)
        case menu(String)

        var id: String {
            switch self {
            case let .expire(value):
                "expire\(value)"
            case let .view(value):
                "view\(value)"
            case let .internalContainer(value):
                "internalContainer\(value)"
            case let .externalContainer(value):
                "externalContainer\(value)"
            case let .stack(value):
                "stack\(value)"
            case let .menu(value):
                "menu\(value)"
            }
        }
    }

    var body: some View {
        mainContainer
            .commonViewSetUpModifier("Secure links")
            .showSpinner(viewModel.loading)
            .toolbar { toolbarContent }
            .if(viewModel.searchSecureLink) { view in
                view.searchable(text: $viewModel.searchText,
                                prompt: "Search")
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.load()
            }
            .animation(.default, value: viewModel.display)
            .animation(.default, value: viewModel.secureLinks)
            .navigationStackEmbeded()
            .tint(PassColor.interactionNorm.toColor)
    }
}

private extension SecureLinkListView {
    @ViewBuilder
    var mainContainer: some View {
        if viewModel.secureLinks.isEmpty {
            VStack {
                Spacer()
                Image(uiImage: PassIcon.securityEmptyState)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 195)
                Text("You currently don't have any secure links")
                    .foregroundStyle(PassColor.textHint.toColor)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxHeight: .infinity)
        } else {
            activeSection
            inactiveSection
        }
    }
}

private extension SecureLinkListView {
    @ViewBuilder
    var activeSection: some View {
        if !viewModel.activeLinks.isEmpty {
            if viewModel.isGrid {
                itemsGrid(items: viewModel.activeLinks)
            } else {
                itemsList(items: viewModel.activeLinks)
            }
        }
    }

    @ViewBuilder
    var inactiveSection: some View {
        if !viewModel.inactiveLinks.isEmpty {
            Section {
                if viewModel.isGrid {
                    itemsGrid(items: viewModel.inactiveLinks, isInactive: true)
                } else {
                    itemsList(items: viewModel.inactiveLinks, isInactive: true)
                }
            } header: {
                HStack {
                    Text("Inactive links")
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DesignConstant.sectionPadding)
                    Spacer()
                    Menu {
                        Button(role: .destructive,
                               action: { viewModel.removeAllInactiveLinks() },
                               label: {
                                   Label(title: {
                                       Text("Remove all inactive links")
                                   }, icon: {
                                       Image(uiImage: IconProvider.crossCircle)
                                   })
                               })
                    } label: {
                        Image(uiImage: IconProvider.threeDotsVertical)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .contentShape(.rect)
                    }
                }
            }
        }
    }
}

private extension SecureLinkListView {
    func itemsGrid(items: [SecureLinkListUIModel], isInactive: Bool = false) -> some View {
        LazyVGrid(columns: columns) {
            ForEach(items) { item in
                itemCell(for: item, isInactive: isInactive)
            }
            Spacer()
        }
    }

    func itemCell(for item: SecureLinkListUIModel, isInactive: Bool) -> some View {
        Group {
            if viewModel.isGrid {
                gridItemCell(for: item, isInactive: isInactive)
            } else {
                listItemCell(for: item, isInactive: isInactive)
            }
        }
        .background(isInactive ? PassColor.textDisabled.toColor : PassColor.interactionNormMinor2.toColor)
        .cornerRadius(20)
        .onTapGesture {
            viewModel.goToDetail(link: item)
        }
        .matchedGeometryEffect(id: GeoMatchIds.stack(item.id).id, in: animation)
    }

    func cellIcon(item: SecureLinkListUIModel) -> some View {
        ItemSquircleThumbnail(data: item.itemContent.thumbnailData())
            .padding(viewModel.isGrid ? .bottom : .trailing, 10)
            .matchedGeometryEffect(id: "icon\(item.secureLink.linkID)", in: animation)
    }

    func cellTitle(item: SecureLinkListUIModel) -> some View {
        Text(item.itemContent.name)
            .matchedGeometryEffect(id: "name\(item.secureLink.linkID)", in: animation)
            .lineLimit(1)
            .foregroundStyle(PassColor.textNorm.toColor)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: viewModel.isGrid ? .center : .leading)
    }

    func gridItemCell(for item: SecureLinkListUIModel, isInactive: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                cellIcon(item: item)

                VStack {
                    cellTitle(item: item)

                    VStack {
                        Text(isInactive ?
                            "Expired \(item.relativeTimeRemaining)" :
                            "Expires \(item.relativeTimeRemaining)")
                            .matchedGeometryEffect(id: GeoMatchIds.expire(item.id).id,
                                                   in: animation)

                        if let readCount = item.secureLink.readCount {
                            Text("\(readCount) view")
                                .matchedGeometryEffect(id: GeoMatchIds.view(item.id).id,
                                                       in: animation)
                        }
                    }
                    .matchedGeometryEffect(id: GeoMatchIds.internalContainer(item.id).id,
                                           in: animation)
                    .font(.caption)
                    .foregroundStyle(PassColor.textWeak.toColor)
                }
                .matchedGeometryEffect(id: GeoMatchIds.externalContainer(item.id).id,
                                       in: animation)
            }
            .padding(24)
            menu(item: item, isInactive: isInactive)
                .padding([.top, .trailing], 16)
        }
        .frame(minWidth: 175, maxWidth: .infinity)
    }

    func listItemCell(for item: SecureLinkListUIModel, isInactive: Bool) -> some View {
        HStack {
            cellIcon(item: item)

            VStack {
                cellTitle(item: item)
                    .padding(.bottom, 5)

                HStack {
                    Text(isInactive ?
                        "Expired \(item.relativeTimeRemaining)" :
                        "Expires \(item.relativeTimeRemaining)")
                        .matchedGeometryEffect(id: GeoMatchIds.expire(item.id).id, in: animation)
                    if let readCount = item.secureLink.readCount {
                        Text(verbatim: "/")
                        Text("\(readCount) view")
                            .matchedGeometryEffect(id: GeoMatchIds.view(item.id).id, in: animation)
                    }
                    Spacer()
                }
                .matchedGeometryEffect(id: GeoMatchIds.internalContainer(item.id).id, in: animation)
                .font(.caption)
                .foregroundStyle(PassColor.textWeak.toColor)
            }
            .matchedGeometryEffect(id: GeoMatchIds.externalContainer(item.id).id, in: animation)

            Spacer()
            menu(item: item, isInactive: isInactive)
        }
        .padding()
    }
}

private extension SecureLinkListView {
    func itemsList(items: [SecureLinkListUIModel], isInactive: Bool = false) -> some View {
        LazyVStack {
            ForEach(items) { item in
                itemCell(for: item, isInactive: isInactive)
                    .frame(maxWidth: .infinity)
                    .animation(.default, value: viewModel.display)
            }
            Spacer()
        }
    }

    func menu(item: SecureLinkListUIModel, isInactive: Bool) -> some View {
        Menu {
            if !isInactive {
                Button { viewModel.copyLink(item) } label: {
                    Label(title: {
                        Text("Copy link")
                    }, icon: {
                        Image(uiImage: IconProvider.squares)
                            .renderingMode(.template)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    })
                }
                Divider()
            }
            Button(role: .destructive,
                   action: { viewModel.deleteLink(link: item) },
                   label: {
                       Label(title: {
                           Text(isInactive ? "Remove inactive link" : "Remove link")
                       }, icon: {
                           Image(uiImage: IconProvider.crossCircle)
                       })
                   })
        } label: {
            Image(uiImage: IconProvider.threeDotsVertical)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(PassColor.textWeak.toColor)
                .contentShape(.rect)
        }
        .simultaneousGesture(TapGesture().onEnded {})
        .matchedGeometryEffect(id: GeoMatchIds.menu(item.id).id, in: animation)
    }
}

private extension SecureLinkListView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }

        if viewModel.searchSecureLink {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleDisplay()
                } label: {
                    Image(systemName: viewModel.isGrid ? "list.bullet.rectangle" : "square.grid.3x3.square")
                }
                .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                .buttonStyle(.plain)
            }
        }
    }
}

/// Set up common UI appearance for item detail pages
/// e.g. navigation bar, background color, toolbar
private struct CommonViewSetUpModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignConstant.sectionPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .toolbarBackground(PassColor.backgroundNorm.toColor,
                               for: .navigationBar)

            .navigationTitle(title)
    }
}

extension View {
    func commonViewSetUpModifier(_ title: String) -> some View {
        modifier(CommonViewSetUpModifier(title: title))
    }
}
