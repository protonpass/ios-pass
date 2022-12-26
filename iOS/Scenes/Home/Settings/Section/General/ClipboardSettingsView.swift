//
// ClipboardSettingsView.swift
// Proton Pass - Created on 26/12/2022.
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

struct ClipboardSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onGoBack: () -> Void

    var body: some View {
        Form {
            Section(content: {
                ForEach(ClipboardExpiration.allCases, id: \.rawValue) { expiration in
                    HStack {
                        Text(expiration.description)
                        Spacer()
                        if viewModel.clipboardExpiration == expiration {
                            Image(systemName: "checkmark")
                                .foregroundColor(.interactionNorm)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.clipboardExpiration = expiration
                        if !UIDevice.current.isIpad {
                            onGoBack()
                        }
                    }
                }
            }, footer: {
                Text("Automatically clear copied content after the selected period of time.")
            })
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("Clear clipboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onGoBack) {
                    Image(uiImage: IconProvider.chevronLeft)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}
