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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct EmptyVaultView: View {
    let action: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: PassIcon.folder)
                .resizable()
                .scaledToFit()
                .frame(width: 150)
            Text("Create your first item\n by clicking the button below")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(action: action, label: {
                Text("New item")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            })
            .padding()
            .background(Color(ColorProvider.BrandNorm))
            .cornerRadius(8)
        }
        .padding(.top, -100)
    }
}
