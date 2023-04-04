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

import ProtonCore_UIFoundations
import SwiftUI

let kSearchBarHeight: CGFloat = 48

struct SearchBar: View {
    @Binding var query: String
    @FocusState var isFocused
    let placeholder: String
    let onCancel: () -> Void

    var body: some View {
        HStack {
            ZStack {
                Color.black
                HStack {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)

                    TextField(placeholder, text: $query)
                        .tint(.passBrand)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .foregroundColor(.primary)

                    Button(action: {
                        query = ""
                    }, label: {
                        Image(uiImage: IconProvider.cross)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    })
                    .buttonStyle(.plain)
                    .opacity(query.isEmpty ? 0 : 1)
                    .animation(.default, value: query.isEmpty)
                }
                .foregroundColor(.textWeak)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .containerShape(Rectangle())

            Button(action: onCancel) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .foregroundColor(.passBrand)
            }
        }
        .frame(height: kSearchBarHeight)
        .padding()
    }
}
