//
// CreateItemView.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateItemView: View {
    @Environment(\.dismiss) private var dismiss
    private let viewModel: CreateItemViewModel

    init(viewModel: CreateItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            NotchView()
                .padding(.top, 5)
                .padding(.bottom, 17)

            Text("Create new")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 15)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(CreateNewItemOption.allCases, id: \.self) { option in
                        GenericItemView(item: option,
                                        action: { viewModel.select(option: option) })
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
