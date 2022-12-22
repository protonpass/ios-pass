//
// ThemesView.swift
// Proton Pass - Created on 22/12/2022.
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

import Core
import ProtonCore_UIFoundations
import SwiftUI

@available(iOS, deprecated: 16.0, message: "No need after dropping iOS 15")
struct ThemesView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onGoBack: () -> Void

    var body: some View {
        Form {
            ForEach(Theme.allCases, id: \.rawValue) { theme in
                HStack {
                    Label(title: {
                        Text(theme.description)
                    }, icon: {
                        Image(uiImage: theme.icon)
                            .foregroundColor(.primary)
                    })

                    Spacer()

                    if viewModel.theme == theme {
                        Image(systemName: "checkmark")
                            .foregroundColor(.interactionNorm)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.theme = theme
                }
            }
        }
        .tint(.interactionNorm)
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: onGoBack) {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("Themes")
        }
    }
}
