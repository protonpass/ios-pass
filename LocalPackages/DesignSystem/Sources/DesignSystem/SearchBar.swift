//
// SearchBar.swift
// Proton Pass - Created on 27/02/2024.
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
//

import ProtonCoreUIFoundations
import SwiftUI

public struct SearchBar: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    let cancelMode: CancelMode
    let onCancel: (() -> Void)?

    public enum CancelMode {
        case never, always, queryNotEmpty

        func shouldShow(query: String) -> Bool {
            switch self {
            case .never:
                false
            case .always:
                true
            case .queryNotEmpty:
                !query.isEmpty
            }
        }
    }

    public init(query: Binding<String>,
                isFocused: FocusState<Bool>.Binding,
                placeholder: String,
                cancelMode: CancelMode,
                onCancel: (() -> Void)? = nil) {
        _query = query
        self.isFocused = isFocused
        self.placeholder = placeholder
        self.cancelMode = cancelMode
        self.onCancel = onCancel
    }

    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                PassColor.backgroundStrong.toColor
                HStack(spacing: 12) {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(width: 20, height: 20)

                    TextField(placeholder, text: $query)
                        .tint(PassColor.interactionNorm.toColor)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .autocorrectionDisabled()
                        .focused(isFocused)
                        .minimumScaleFactor(0.75)

                    Button(action: {
                        query = ""
                    }, label: {
                        Image(uiImage: IconProvider.cross)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .frame(width: 24, height: 24)
                    })
                    .buttonStyle(.plain)
                    .opacity(query.isEmpty ? 0 : 1)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(.rect)
            if let onCancel, cancelMode.shouldShow(query: query) {
                Button(action: onCancel) {
                    Text("Cancel", bundle: .module)
                        .fontWeight(.semibold)
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                }
            }
        }
        .frame(height: DesignConstant.searchBarHeight)
        .padding()
        .animation(.default, value: query.isEmpty)
    }
}
