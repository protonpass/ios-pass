//
// AdvancedOptionsSection.swift
// Proton Pass - Created on 21/02/2023.
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

struct AdvancedOptionsSection: View {
    @Binding var isShowingAdvancedOptions: Bool

    var body: some View {
        Button(action: {
            isShowingAdvancedOptions.toggle()
        }, label: {
            Label(title: {
                Text("Advanced options")
                    .font(.callout)
            }, icon: {
                IconProvider.cogWheel
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
            })
            .foregroundStyle(PassColor.textWeak)
            .frame(maxWidth: .infinity, alignment: .trailing)
        })
    }
}
