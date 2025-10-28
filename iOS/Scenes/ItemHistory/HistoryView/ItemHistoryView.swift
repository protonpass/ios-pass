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
import Screens
import SwiftUI

struct ItemHistoryView: View {
    @StateObject var viewModel: ItemHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var showResetHistoryAlert = false

    private enum ElementSizes {
        static let circleSize: CGFloat = 15
        static let line: CGFloat = 1
        static let cellHeight: CGFloat = 75

        static var minSpacerSize: CGFloat {
            (ElementSizes.cellHeight - ElementSizes.circleSize / 2) / 2
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let lastUsed = viewModel.lastUsedTime {
                header(lastUsed: lastUsed)
            }

            if !viewModel.history.isEmpty {
                historyListView
            }

            Spacer()
        }
        .animation(.default, value: viewModel.history)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .navigationTitle("History")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm)
        .showSpinner(viewModel.loading)
        .routingProvided
        .navigationStackEmbeded($path)
        .alert("Reset history for this item?",
               isPresented: $showResetHistoryAlert,
               actions: {
                   Button(role: .destructive,
                          action: viewModel.resetHistory,
                          label: { Text("Reset") })

                   Button(role: .cancel, action: {}, label: { Text("Cancel") })
               },
               message: {
                   Text("Resetting history will permanently delete all past versions and cannot be undone.")
               })
    }
}

private extension ItemHistoryView {
    @ViewBuilder
    func header(lastUsed: String) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.magicWand,
                                  color: PassColor.textWeak)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Last autofill")
                    .foregroundStyle(PassColor.textNorm)
                Text(lastUsed)
                    .font(.footnote)
                    .foregroundStyle(PassColor.textWeak)
            }
            .contentShape(.rect)
        }
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)

        Text("Changelog")
            .foregroundStyle(PassColor.textNorm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension ItemHistoryView {
    var historyListView: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.history, id: \.item.revision) { item in
                if viewModel.isCurrentRevision(item) {
                    currentCell(item: item)
                } else if viewModel.isCreationRevision(item) {
                    navigationLink(for: item, view: creationCell(item: item))
                } else {
                    navigationLink(for: item, view: modificationCell(item: item))
                        .onAppear {
                            viewModel.loadMoreContentIfNeeded(item: item)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    func creationCell(item: ItemContent) -> some View {
        HStack {
            VStack(spacing: 0) {
                verticalLine

                Circle()
                    .background(Circle().foregroundStyle(PassColor.textWeak))
                    .frame(width: ElementSizes.circleSize, height: ElementSizes.circleSize)

                Spacer(minLength: ElementSizes.minSpacerSize)
            }
            infoRow(title: "Created", infos: item.creationDate, icon: IconProvider.bolt)
                .padding(.top, 8)
        }
    }

    func currentCell(item: ItemContent) -> some View {
        HStack {
            VStack(spacing: 0) {
                Spacer(minLength: ElementSizes.minSpacerSize)

                Circle()
                    .strokeBorder(PassColor.textWeak, lineWidth: 1)
                    .frame(width: ElementSizes.circleSize, height: ElementSizes.circleSize)

                if viewModel.history.count > 1 {
                    verticalLine
                } else {
                    Spacer(minLength: ElementSizes.minSpacerSize)
                }
            }
            infoRow(title: "Current version",
                    infos: item.modificationDate,
                    icon: IconProvider.clock,
                    shouldDisplay: false)
        }
    }

    func modificationCell(item: ItemContent) -> some View {
        HStack {
            VStack(spacing: 0) {
                verticalLine

                Circle()
                    .background(Circle().foregroundStyle(PassColor.textWeak))
                    .frame(width: ElementSizes.circleSize, height: ElementSizes.circleSize)

                verticalLine
            }
            infoRow(title: "Modified", infos: item.revisionDate, icon: IconProvider.pencil)
                .padding(.top, 8)
        }
    }

    func navigationLink(for item: ItemContent, view: some View) -> some View {
        NavigationLink(value: GeneralRouterDestination
            .historyDetail(currentRevision: viewModel.item,
                           pastRevision: item,
                           files: viewModel.files),
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
                    .foregroundStyle(PassColor.textNorm)
                if let infos {
                    Text(infos)
                        .font(.footnote)
                        .foregroundStyle(PassColor.textWeak)
                }
            }
            .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
            .contentShape(.rect)
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
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: viewModel.item.contentData.type.normMajor2Color,
                         backgroundColor: viewModel.item.contentData.type.normMinor1Color,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu(content: {
                Button("Reset history",
                       systemImage: "arrow.counterclockwise.circle",
                       role: .destructive,
                       action: { showResetHistoryAlert.toggle() })
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: viewModel.item.type.normMajor2Color,
                             backgroundColor: viewModel.item.type.normMinor1Color,
                             accessibilityLabel: "Item's action Menu")
            })
        }
    }
}

// MARK: - UIElements

private extension ItemHistoryView {
    var verticalLine: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(maxWidth: ElementSizes.line, maxHeight: .infinity)
            .background(PassColor.textWeak)
    }
}
