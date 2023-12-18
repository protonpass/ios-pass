//
// SortTypeListView.swift
// Proton Pass - Created on 09/03/2023.
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

import Client
import Core
import DesignSystem
import SwiftUI

@MainActor
protocol SortTypeListViewModelDelegate: AnyObject {
    func sortTypeListViewDidSelect(_ sortType: SortType)
}

@MainActor
final class SortTypeListViewModel: ObservableObject, DeinitPrintable, Sendable {
    deinit { print(deinitMessage) }

    @Published var selectedSortType: SortType {
        didSet {
            delegate?.sortTypeListViewDidSelect(selectedSortType)
        }
    }

    weak var delegate: SortTypeListViewModelDelegate?

    init(sortType: SortType) {
        selectedSortType = sortType
    }
}

struct SortTypeListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SortTypeListViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(SortType.allCases, id: \.self) { type in
                    SelectableOptionRow(action: {
                                            viewModel.selectedSortType = type
                                            dismiss()
                                        },
                                        height: .compact,
                                        content: {
                                            Text(type.title)
                                                .foregroundColor(Color(uiColor: type == viewModel
                                                        .selectedSortType ?
                                                        PassColor.interactionNormMajor2 : PassColor.textNorm))
                                        },
                                        isSelected: type == viewModel.selectedSortType)

                    PassDivider()
                }
                .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sort By")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
