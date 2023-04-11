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
    @StateObject var vaultsManager: VaultsManager

    var body: some View {
        switch vaultsManager.state {
        case .loading:
            skeleton
        case let .loaded(vaults, trashedItems):
            let activeItems = vaults.map { $0.items }.reduce(into: [], { $0 = $0 + $1 })
            let allItems = activeItems + trashedItems
            let itemCount = ItemCount(items: allItems)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ItemContentTypeCountView(type: .login, count: itemCount.loginCount)
                    ItemContentTypeCountView(type: .alias, count: itemCount.aliasCount)
                    ItemContentTypeCountView(type: .note, count: itemCount.noteCount)
                }
                .padding(.horizontal)
            }
        case .error(let error):
            Text(error.messageForTheUser)
                .foregroundColor(Color(uiColor: PassColor.signalDanger))
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
}

private struct ItemContentTypeCountView: View {
    let type: ItemContentType
    let count: Int

    var body: some View {
        HStack {
            CircleButton(icon: type.icon,
                         iconColor: type.tintColor,
                         backgroundColor: type.backgroundNormColor,
                         height: 36)

            Spacer()

            Text("\(count)")
                .fontWeight(.bold)
                .foregroundColor(Color(uiColor: PassColor.textNorm))

            Spacer()
        }
        .padding(10)
        .frame(height: kChipHeight)
        .frame(minWidth: 103)
        .overlay(Capsule().strokeBorder(Color(uiColor: PassColor.inputBorderNorm), lineWidth: 1))
    }
}
