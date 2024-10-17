//
// LoginsWith2faView.swift
// Proton Pass - Created on 16/10/2024.
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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct LoginsWith2faView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: LoginsWith2faViewModel

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            LazyVStack(spacing: 0) {
                ForEach(viewModel.items) { item in
                    Button {
                        viewModel.select(item)
                    } label: {
                        GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                                       title: item.title,
                                       description: item.description)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .scrollViewEmbeded()
        }
        .navigationTitle("Logins with 2FA")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }
        }
        .navigationStackEmbeded()
    }
}
