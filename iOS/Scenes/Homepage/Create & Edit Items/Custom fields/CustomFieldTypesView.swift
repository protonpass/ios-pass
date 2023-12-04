//
// CustomFieldTypesView.swift
// Proton Pass - Created on 10/05/2023.
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

import Client
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CustomFieldTypesView: View {
    let onSelect: (CustomFieldType) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(CustomFieldType.allCases, id: \.self) { type in
                    row(for: type)
                    PassDivider()
                }
            }
            .padding()
        }
        .background(Color(uiColor: PassColor.backgroundWeak))
    }

    private func row(for type: CustomFieldType) -> some View {
        Button(action: {
            onSelect(type)
        }, label: {
            HStack(spacing: 18) {
                Image(uiImage: type.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: PassColor.textWeak))
                    .frame(maxWidth: 20)

                Text(type.title)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))

                Spacer()
            }
            .frame(height: OptionRowHeight.short.value, alignment: .leading)
        })
    }
}

extension CustomFieldType {
    var title: String {
        switch self {
        case .text:
            #localized("Text")
        case .totp:
            #localized("2FA secret (TOTP)")
        case .hidden:
            #localized("Hidden")
        }
    }

    var icon: UIImage {
        switch self {
        case .text:
            IconProvider.textAlignLeft
        case .totp:
            IconProvider.lock
        case .hidden:
            IconProvider.eyeSlash
        }
    }
}
