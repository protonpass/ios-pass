//
// ItemTypeListView.swift
// Proton Pass - Created on 06/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

struct ItemTypeListView: View {
    @StateObject private var viewModel: ItemTypeListViewModel

    init(viewModel: ItemTypeListViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.mode.supportedTypes, id: \.self) { type in
                            if type != ItemType.allCases.first {
                                PassDivider()
                                    .padding(.horizontal)
                            }
                            itemRow(for: type)
                                .padding(.horizontal)
                        }
                    }
                }
                if viewModel.mode.shouldShowMoreButton, viewModel.showMoreButton {
                    Button { viewModel.showMore() } label: {
                        HStack {
                            Image(uiImage: IconProvider.chevronDown)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text("Scroll for more")
                                .font(.callout)
                        }
                        .padding(10)
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    }
                    .background(PassColor.interactionNormMinor1.toColor)
                    .clipShape(Capsule())
                }
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: viewModel.showMoreButton)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create")
                        .navigationTitleText()
                }
            }
        }
    }

    private func itemRow(for type: ItemType) -> some View {
        Button(action: {
            viewModel.select(type: type)
        }, label: {
            GeneralItemRow(thumbnailView: {
                               SquircleThumbnail(data: .icon(type.icon),
                                                 tintColor: type.tintColor,
                                                 backgroundColor: type.backgroundColor)
                           },
                           title: type.title,
                           description: type.description,
                           descriptionLineLimit: 2,
                           secondaryTitle: secondaryTitle(for: type),
                           secondaryTitleColor: secondaryTitleColor(for: type))
        })
        .buttonStyle(.plain)
    }

    private func secondaryTitle(for type: ItemType) -> String? {
        guard case .alias = type, let limitation = viewModel.limitation else {
            return nil
        }
        return "(\(limitation.count)/\(limitation.limit))"
    }

    private func secondaryTitleColor(for type: ItemType) -> UIColor? {
        guard case .alias = type, let limitation = viewModel.limitation else {
            return nil
        }
        return limitation.count < limitation.limit ? PassColor.textWeak : PassColor.signalDanger
    }
}
