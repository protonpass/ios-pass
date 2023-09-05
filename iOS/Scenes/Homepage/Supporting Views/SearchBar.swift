//
// SearchBar.swift
// Proton Pass - Created on 04/04/2023.
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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

let kSearchBarHeight: CGFloat = 48

struct SearchBar: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Color(uiColor: PassColor.backgroundStrong)
                HStack(spacing: 12) {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(uiColor: PassColor.textWeak))
                        .frame(width: 20, height: 20)

                    TextField(placeholder, text: $query)
                        .tint(Color(uiColor: PassColor.interactionNorm))
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                        .autocorrectionDisabled()
                        .focused(isFocused)
                        .minimumScaleFactor(0.75)

                    Button(action: {
                        query = ""
                    }, label: {
                        Image(uiImage: IconProvider.cross)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                            .frame(width: 24, height: 24)
                    })
                    .buttonStyle(.plain)
                    .opacity(query.isEmpty ? 0 : 1)
                    .animation(.default, value: query.isEmpty)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .containerShape(Rectangle())

            Button(action: onCancel) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
            }
        }
        .frame(height: kSearchBarHeight)
        .padding()
    }
}
