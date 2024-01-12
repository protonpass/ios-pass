//
//
// ItemHistoryView.swift
// Proton Pass - Created on 09/01/2024.
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

struct ItemHistoryView: View {
    @StateObject var viewModel: ItemHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    private enum ElementSizes {
        static let circleSize: CGFloat = 15
        static let line: CGFloat = 1
        static let cellHeight: CGFloat = 75

        static var minSpacerSize: CGFloat {
            (ElementSizes.cellHeight - ElementSizes.circleSize / 2) / 2
        }
    }

    var body: some View {
        mainContainer
            .task {
                await viewModel.loadItemHistory()
            }
    }
}

private extension ItemHistoryView {
    var mainContainer: some View {
        VStack(alignment: .leading) {
            if let lastUsed = viewModel.lastUsedTime {
                header(lastUsed: lastUsed)
            }
            if viewModel.state == .loading {
                progressView
            } else if !viewModel.state.history.isEmpty {
                historyListView
            } else {
                EmptyView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .animation(.default, value: viewModel.state)
        .navigationTitle("History")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .routingProvided
        .navigationStackEmbeded($path)
    }
}

private extension ItemHistoryView {
    func header(lastUsed: String) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: DesignConstant.sectionPadding) {
                ItemDetailSectionIcon(icon: IconProvider.magicWand,
                                      color: PassColor.textWeak)

                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text("Last autofill")
                        .font(.body)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    Text(lastUsed)
                        .font(.footnote)
                        .foregroundColor(PassColor.textWeak.toColor)
                }
                .contentShape(Rectangle())
            }
            .padding(.bottom, 20)

            Text("Changelog")
                .font(.body)
                .foregroundStyle(PassColor.textNorm.toColor)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private extension ItemHistoryView {
    var progressView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private extension ItemHistoryView {
    var historyListView: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.state.history, id: \.item.revision) { item in
                if viewModel.isCurrentRevision(item) {
                    currentCell()
                } else if viewModel.isCreationRevision(item) {
                    navigationLink(for: item, view: creationCell(item: item))
                } else {
                    navigationLink(for: item, view: modificationCell(item: item))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .scrollViewEmbeded(maxWidth: .infinity)
    }

    func creationCell(item: ItemContent) -> some View {
        HStack {
            VStack(spacing: 0) {
                verticalLine

                Circle()
                    .background(Circle().foregroundColor(PassColor.textWeak.toColor))
                    .frame(width: ElementSizes.circleSize, height: ElementSizes.circleSize)

                Spacer(minLength: ElementSizes.minSpacerSize)
            }
            infoRow(title: "Created", infos: item.creationDate, icon: IconProvider.bolt)
                .padding(.top, 8)
        }
    }

    func currentCell() -> some View {
        HStack {
            VStack(spacing: 0) {
                Spacer(minLength: ElementSizes.minSpacerSize)

                Circle()
                    .strokeBorder(PassColor.textWeak.toColor, lineWidth: 1)
                    .frame(width: ElementSizes.circleSize, height: ElementSizes.circleSize)

                if viewModel.state.history.count > 1 {
                    verticalLine
                } else {
                    Spacer(minLength: ElementSizes.minSpacerSize)
                }
            }
            infoRow(title: "Current version",
                    infos: nil,
                    icon: IconProvider.clock,
                    shouldDisplay: false)
        }
    }

    func modificationCell(item: ItemContent) -> some View {
        HStack {
            VStack(spacing: 0) {
                verticalLine

                Circle()
                    .background(Circle().foregroundColor(PassColor.textWeak.toColor))
                    .frame(width: ElementSizes.circleSize, height: ElementSizes.circleSize)

                verticalLine
            }
            infoRow(title: "Modified", infos: item.revisionDate, icon: IconProvider.pencil)
                .padding(.top, 8)
        }
    }

    func navigationLink(for item: ItemContent, view: some View) -> some View {
        NavigationLink(value: GeneralRouterDestination
            .historyDetail(currentRevision: viewModel.item, pastRevision: item),
            label: {
                view
            })
            .isDetailLink(false)
            .buttonStyle(.plain)
    }
}

private extension ItemHistoryView {
    func infoRow(title: LocalizedStringKey,
                 infos: String?,
                 icon: UIImage,
                 shouldDisplay: Bool = true) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: icon,
                                  color: PassColor.textWeak)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                if let infos {
                    Text(infos)
                        .font(.footnote)
                        .foregroundColor(PassColor.textWeak.toColor)
                }
            }
            .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
            .contentShape(Rectangle())
            if shouldDisplay {
                ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                      color: PassColor.textWeak)
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

private extension ItemHistoryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: viewModel.item.contentData.type.normMajor2Color,
                         backgroundColor: viewModel.item.contentData.type.normMinor1Color) {
                dismiss()
            }
        }
    }
}

// MARK: - UIElements

private extension ItemHistoryView {
    var verticalLine: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(maxWidth: ElementSizes.line, maxHeight: .infinity)
            .background(PassColor.textWeak.toColor)
    }
}
