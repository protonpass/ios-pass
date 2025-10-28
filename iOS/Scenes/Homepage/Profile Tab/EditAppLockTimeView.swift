//
// EditAppLockTimeView.swift
// Proton Pass - Created on 27/04/2023.
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
import Entities
import SwiftUI

struct EditAppLockTimeView: View {
    let selectedAppLockTime: AppLockTime
    let onSelect: (AppLockTime) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(AppLockTime.allCases, id: \.rawValue) { time in
                        SelectableOptionRow(action: { onSelect(time) },
                                            height: .compact,
                                            content: {
                                                Text(time.description)
                                                    .foregroundStyle(PassColor.textNorm)
                                            },
                                            isSelected: time == selectedAppLockTime)

                        PassDivider()
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PassColor.backgroundWeak)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Automatic lock")
                        .navigationTitleText()
                }
            }
        }
    }
}
