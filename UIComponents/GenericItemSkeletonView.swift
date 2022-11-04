//
// GenericItemSkeletonView.swift
// Proton Pass - Created on 04/11/2022.
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

import SwiftUI

public struct GenericItemSkeletonView: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            AnimatingGrayGradient()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                Spacer()
                AnimatingGrayGradient()
                    .frame(width: 170, height: 10)
                    .clipShape(Capsule())
                Spacer()
                AnimatingGrayGradient()
                    .frame(width: 200, height: 10)
                    .clipShape(Capsule())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AnimatingGrayGradient: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            Color(.systemGray6)
            LinearGradient(colors: [.clear, Color(.systemGray5), .clear],
                           startPoint: .leading,
                           endPoint: .trailing)
            .offset(x: animateGradient ? 300 : -200)
            .frame(width: 200)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                animateGradient.toggle()
            }
        }
    }
}
