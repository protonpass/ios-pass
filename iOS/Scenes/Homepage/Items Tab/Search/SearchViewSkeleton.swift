//
// SearchViewSkeleton.swift
// Proton Pass - Created on 13/03/2023.
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
import SwiftUI

struct SearchViewSkeleton: View {
    var body: some View {
        VStack {
            HStack {
                SkeletonBlock()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                SkeletonBlock()
                    .frame(width: kSearchBarHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: kSearchBarHeight)
            .shimmering()

            HStack {
                SkeletonBlock()
                    .frame(width: 160)
                    .clipShape(Capsule())

                Spacer()

                SkeletonBlock()
                    .frame(width: 50)
                    .clipShape(Capsule())
            }
            .frame(height: 18)
            .frame(maxWidth: .infinity)
            .shimmering()

            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<20, id: \.self) { _ in
                        itemRow
                    }
                }
            }
            .disabled(true)
        }
        .padding(.top, 24)
        .padding(.horizontal)
    }

    private var itemRow: some View {
        HStack(spacing: 16) {
            SkeletonBlock()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading) {
                Spacer()
                SkeletonBlock()
                    .frame(width: 170, height: 10)
                    .clipShape(Capsule())
                Spacer()
                SkeletonBlock()
                    .frame(width: 200, height: 10)
                    .clipShape(Capsule())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shimmering()
    }
}
