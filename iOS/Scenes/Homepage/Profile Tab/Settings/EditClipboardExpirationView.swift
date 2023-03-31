//
// EditClipboardExpirationView.swift
// Proton Pass - Created on 31/03/2023.
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

import Core
import SwiftUI
import UIComponents

struct EditClipboardExpirationView: View {
    @Environment(\.dismiss) private var dismiss
    let preferences: Preferences

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 22) {
                NotchView()
                    .padding(.top, 5)
                Text("Clear clipboard")
                    .navigationTitleText()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ClipboardExpiration.allCases, id: \.rawValue) { expiration in
                        OptionRow(
                            action: { preferences.clipboardExpiration = expiration; dismiss() },
                            height: CGFloat(kOptionRowCompactHeight),
                            content: { Text(expiration.description) },
                            trailing: {
                                if expiration == preferences.clipboardExpiration {
                                    Label("", systemImage: "checkmark")
                                        .foregroundColor(.passBrand)
                                }
                            })

                        if expiration != ClipboardExpiration.allCases.last {
                            PassDivider()
                        }
                    }
                }
                .roundedEditableSection()
                .padding(.top)
            }
            .padding(.horizontal)
        }
        .background(Color.passSecondaryBackground)
    }
}
