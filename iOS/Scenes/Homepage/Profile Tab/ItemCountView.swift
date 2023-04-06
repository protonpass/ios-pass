//
// ItemCountView.swift
// Proton Pass - Created on 30/03/2023.
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
import SwiftUI
import UIComponents

private let kChipHeight: CGFloat = 56

struct ItemCountView: View {
    @StateObject var viewModel: ItemCountViewModel

    var body: some View {
        switch viewModel.state {
        case .loading:
            skeleton
        case .loaded(let itemCount):
            content(for: itemCount)
        case .error:
            Button("Retry", action: viewModel.refresh)
        }
    }

    private var skeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0...5, id: \.self) { _ in
                    AnimatingGradient()
                        .frame(width: 100, height: kChipHeight)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .adaptiveScrollDisabled(true)
    }

    private func content(for itemCount: ItemCount) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ItemContentTypeCountView(type: .login, count: itemCount.loginCount)
                ItemContentTypeCountView(type: .alias, count: itemCount.aliasCount)
                ItemContentTypeCountView(type: .note, count: itemCount.noteCount)
            }
            .padding(.horizontal)
        }
    }
}

private struct ItemContentTypeCountView: View {
    let type: ItemContentType
    let count: Int

    var body: some View {
        HStack {
            ZStack {
                Color(uiColor: type.tintColor)
                    .opacity(0.16)
                Image(uiImage: type.chipIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
                    .foregroundColor(Color(uiColor: type.tintColor))
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            Spacer()

            Text("\(count)")
                .fontWeight(.bold)

            Spacer()
        }
        .padding(10)
        .frame(height: kChipHeight)
        .frame(minWidth: 103)
        .overlay(Capsule().strokeBorder(Color(uiColor: PassColor.inputBorderNorm), lineWidth: 2))
    }
}
