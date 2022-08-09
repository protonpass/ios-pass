//
// CategorySummaryView.swift
// Proton Pass - Created on 07/07/2022.
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

public struct CategorySummary {
    let icon: UIImage
    let backgroundColor: UIColor
    let text: String

    public init(icon: UIImage,
                backgroundColor: UIColor,
                text: String) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.text = text
    }

    public init(aliasCount: Int) {
        self.icon = IconProvider.alias
        self.backgroundColor = ColorProvider.BrandDarken40
        self.text = "\(aliasCount) aliases"
    }

    public init(loginCount: Int) {
        self.icon = IconProvider.keySkeleton
        self.backgroundColor = ColorProvider.BrandNorm
        self.text = "\(loginCount) logins"
    }

    public init(noteCount: Int) {
        self.icon = IconProvider.note
        self.backgroundColor = ColorProvider.BrandLighten20
        self.text = "\(noteCount) notes"
    }
}

public struct CategorySummaryView: View {
    private let summary: CategorySummary

    public init(summary: CategorySummary) {
        self.summary = summary
    }

    public var body: some View {
        VStack {
            Spacer()
            VStack {
                HStack {
                    Image(uiImage: summary.icon)
                    Spacer()
                }
                Text(summary.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundColor(.white)
            .padding()
        }
        .background(Color(summary.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
