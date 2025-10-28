//
// EmptyTrashView.swift
// Proton Pass - Created on 09/09/2022.
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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct EmptyTrashView: View {
    var body: some View {
        VStack {
            VStack {
                Spacer()
                Image(uiImage: PassIcon.trash)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160)
            }

            VStack {
                Text("Trash empty")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.vertical)
                    .foregroundStyle(PassColor.textNorm)
                Text("Items moved to trash appear here")
                    .foregroundStyle(PassColor.textWeak)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
