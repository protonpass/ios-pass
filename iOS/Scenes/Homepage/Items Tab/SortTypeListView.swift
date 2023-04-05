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
import SwiftUI
import UIComponents

protocol SortTypeListViewModelDelegate: AnyObject {
    func sortTypeListViewDidSelect(_ sortType: SortType)
}

final class SortTypeListViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var selectedSortType: SortType {
        didSet {
            delegate?.sortTypeListViewDidSelect(selectedSortType)
        }
    }

    weak var delegate: SortTypeListViewModelDelegate?

    init(sortType: SortType) {
        self.selectedSortType = sortType
    }
}

struct SortTypeListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SortTypeListViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            NotchView()
                .padding(.top, 5)

            Text("Sort by")
                .font(.callout)
                .fontWeight(.bold)
                .padding(.top, 22)

            ForEach(SortType.allCases, id: \.self) { type in
                HStack {
                    Text(type.title)
                    Spacer()
                    if type == viewModel.selectedSortType {
                        Label("", systemImage: "checkmark")
                    }
                }
                .foregroundColor(type == viewModel.selectedSortType ?
                                 Color(uiColor: PassColor.interactionNorm) : Color(uiColor: PassColor.textNorm))
                .contentShape(Rectangle())
                .frame(height: 44)
                .onTapGesture {
                    viewModel.selectedSortType = type
                    dismiss()
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(uiColor: PassColor.backgroundWeak))
    }
}
