//
// VaultSummaryView.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Key is free software: you can redistribute it and/or modify
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

struct VaultSummaryView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(Color(.secondaryLabel))
                .padding(.vertical)
            HStack {
                CategorySummaryView(summary: CategorySummary.aliases)
                CategorySummaryView(summary: CategorySummary.logins)
                CategorySummaryView(summary: CategorySummary.notes)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VaultSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        VaultSummaryView()
    }
}

struct CategorySummary: CategorySummaryProvider {
    let icon: UIImage
    let backgroundColor: UIColor
    let text: String

    static let aliases = CategorySummary(icon: IconProvider.alias,
                                         backgroundColor: ColorProvider.BrandDarken40,
                                         text: "32 aliases")
    static let logins = CategorySummary(icon: IconProvider.keySkeleton,
                                        backgroundColor: ColorProvider.BrandNorm,
                                        text: "47 logins")
    static let notes = CategorySummary(icon: IconProvider.note,
                                       backgroundColor: ColorProvider.BrandLighten20,
                                       text: "11 notes")
}
