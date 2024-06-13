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
    @StateObject var viewModel: SecureLinkListViewModel
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let iPadColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

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
            .searchable(text: $viewModel.searchText,
                        prompt: "Search")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.load()
            }
            .animation(.default, value: viewModel.display)
            .animation(.default, value: viewModel.secureLinks)
            .navigationStackEmbeded()
    }
}

private extension SecureLinkListView {
    @ViewBuilder
    var mainContainer: some View {
        if let secureLinks = viewModel.secureLinks {
            if viewModel.display == .cell {
                itemsGrid(items: secureLinks)
            } else {
                itemsList(items: secureLinks)
            }
        }
    }
}

private extension SecureLinkListView {
    func itemsGrid(items: [SecureLinkListUIModel]) -> some View {
        LazyVGrid(columns: viewModel.isPhone ? columns : iPadColumns) {
            ForEach(items) { item in
                itemCell(for: item)
            }
            Spacer()
        }
    }

    @ViewBuilder
    func itemCell(for item: SecureLinkListUIModel) -> some View {
        if viewModel.display == .cell {
            ZStack(alignment: .topTrailing) {
                VStack {
                    cellIcon(item: item)

                    VStack {
                        cellTitle(item: item)

                        VStack {
                            Text("Expires in \(item.relativeTimeRemaining)")
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
                menu(item: item)
                    .padding([.top, .trailing], 16)
            }
            .frame(minWidth: 175, maxWidth: .infinity)
            .background(PassColor.interactionNormMinor2.toColor)
            .cornerRadius(20)
            .onTapGesture {
                viewModel.goToDetail(link: item)
            }
            .matchedGeometryEffect(id: GeoMatchIds.stack(item.id).id, in: animation)
        } else {
            HStack {
                cellIcon(item: item)

                VStack {
                    cellTitle(item: item)
                        .padding(.bottom, 5)

                    HStack {
                        Text("Expires in \(item.relativeTimeRemaining)")
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
                menu(item: item)
            }
            .padding()
            .background(PassColor.interactionNormMinor2.toColor)
            .cornerRadius(20)
            .onTapGesture {
                viewModel.goToDetail(link: item)
            }
            .matchedGeometryEffect(id: GeoMatchIds.stack(item.id).id, in: animation)
        }
    }

    func cellIcon(item: SecureLinkListUIModel) -> some View {
        ItemSquircleThumbnail(data: item.itemContent.thumbnailData())
            .padding(viewModel.display == .cell ? .bottom : .trailing, 10)
            .matchedGeometryEffect(id: "icon\(item.secureLink.linkID)", in: animation)
    }

    func cellTitle(item: SecureLinkListUIModel) -> some View {
        Text(item.itemContent.name)
            .matchedGeometryEffect(id: "name\(item.secureLink.linkID)", in: animation)
            .lineLimit(1)
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, alignment: viewModel.display == .cell ? .center : .leading)
    }
}

private extension SecureLinkListView {
    func itemsList(items: [SecureLinkListUIModel]) -> some View {
        LazyVStack {
            ForEach(items) { item in
                itemCell(for: item)
                    .frame(maxWidth: .infinity)
                    .animation(.default, value: viewModel.display)
            }
            Spacer()
        }
    }

    func menu(item: SecureLinkListUIModel) -> some View {
        Menu {
            Button { viewModel.copyLink(item) } label: {
                Label(title: {
                    Text("Copy link")
                }, icon: {
                    Image(uiImage: IconProvider.squares)
                        .renderingMode(.template)
                        .foregroundStyle(PassColor.textWeak.toColor)
                })
            }
            Button(role: .destructive,
                   action: { viewModel.deleteLink(link: item) },
                   label: {
                       Label(title: {
                           Text("Remove link")
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
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                viewModel.displayToggle()
            } label: {
                if viewModel.display == .cell {
                    Image(systemName: "list.bullet.rectangle")
                } else {
                    Image(systemName: "square.grid.3x3.square")
                }
            }.buttonStyle(.plain)
        }
    }
}

struct SecureLinkListView_Previews: PreviewProvider {
    static var previews: some View {
        SecureLinkListView(viewModel: .init(links: []))
    }
}

/// Set up common UI appearance for item detail pages
/// e.g. navigation bar, background color, toolbar, delete item alert...
struct CommonViewSetUpModifier: ViewModifier {
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
