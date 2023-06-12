//
// EmptyVaultView.swift
// Proton Pass - Created on 07/09/2022.
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

import Client
import SwiftUI
import UIComponents

struct EmptyVaultView: View {
    let onCreate: (ItemContentType) -> Void

    var body: some View {
        VStack(alignment: .center) {
            Text("Your vault is empty")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(uiColor: PassColor.textNorm))
                .padding(.bottom, 8)

            Text("Let's get started by creating your first item")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)

            ForEach(ItemContentType.allCases, id: \.self) { type in
                CreateItemButton(type: type) {
                    onCreate(type)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CreateItemButton: View {
    let type: ItemContentType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                type.normMinor1Color.toColor
                HStack {
                    iconImage
                    Spacer()
                    Text(type.createItemTitle)
                    Spacer()
                    // Gimmick image to help center text
                    iconImage
                        .opacity(0)
                }
                .padding(.horizontal)
            }
            .frame(height: 52)
            .clipShape(Capsule())
            .foregroundColor(type.normColor.toColor)
        }
    }

    private var iconImage: some View {
        Image(uiImage: type.icon)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 16, maxHeight: 16)
    }
}

private extension ItemContentType {
    var createItemTitle: String {
        switch self {
        case .login:
            return "Create a login"
        case .alias:
            return "Create a Hide My Email alias"
        case .note:
            return "Create a note"
        }
    }
}
