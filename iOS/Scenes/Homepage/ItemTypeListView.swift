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

import SwiftUI
import UIComponents

struct ItemTypeListView: View {
    @StateObject private var viewModel: ItemTypeListViewModel

    init(viewModel: ItemTypeListViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.supportedItemTypes, id: \.self) { type in
                        itemRow(for: type)
                            .padding(.horizontal)
                        if type != ItemType.allCases.last {
                            PassDivider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func itemRow(for type: ItemType) -> some View {
        Button(action: {
            viewModel.select(type: type)
        }, label: {
            GeneralItemRow(
                thumbnailView: {
                    SquircleThumbnail(data: .icon(type.icon),
                                      tintColor: type.tintColor,
                                      backgroundColor: type.backgroundColor)
                },
                title: type.title,
                description: type.description,
                descriptionMinScaleFactor: 0.9,
                secondaryTitle: secondaryTitle(for: type),
                secondaryTitleColor: secondaryTitleColor(for: type))
            .frame(height: 66)
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
